# Darwin (macOS) System Configuration
#
# Mirrors the NixOS hosts/configuration.nix structure.
# Shared home-manager config comes from modules/home/.
# Darwin-specific system config lives here.
#
#  flake.nix
#   └─ darwinConfigurations."joel"
#       └─ ./darwin/default.nix *
#           ├─ ../modules/home (shared HM modules)
#           ├─ ./homebrew.nix
#           ├─ ./networking.nix
#           └─ ./network-audit.nix

{ config, lib, pkgs, inputs, vars, ... }:

let
  claude-code = pkgs.callPackage ../pkgs/claude-code.nix {};
  # Official native binary and bundled helpers; avoids a local Rust/V8 build.
  codex = pkgs.callPackage ../pkgs/codex.nix {};

  # Removes the folders that ended Nix builds left in the build directory.
  # The folder name holds the process of the build (nix-<pid>-<number>). The
  # process list is taken after the folders, so the process of every listed
  # folder whose build still runs is in it. A folder goes only when its process
  # is not in that list or is not a Nix process, and when it is older than six
  # hours. Without a process list that holds this script, nothing is removed.
  # The argument serves a test with another directory.
  nixBuildSweep = pkgs.writeShellScript "nix-build-sweep" ''
    set -uo pipefail
    builds=''${1:-/nix/var/nix/builds}
    dirs=("$builds"/nix-*)
    table=$(/bin/ps -A -o pid=,comm=) || exit 1
    /usr/bin/grep -qE "^ *$$ " <<< "$table" || exit 1
    for dir in "''${dirs[@]}"; do
      [ -d "$dir" ] && [ ! -L "$dir" ] || continue
      [[ "''${dir##*/}" =~ ^nix-([0-9]+)-[0-9]+$ ]] || continue
      line=$(/usr/bin/grep -E "^ *''${BASH_REMATCH[1]} " <<< "$table" || true)
      [[ "$line" != *nix* ]] || continue
      [ -n "$(/usr/bin/find "$dir" -maxdepth 0 -mmin +360)" ] || continue
      /bin/rm -rf "$dir" && echo "$(/bin/date '+%Y-%m-%d %H:%M') removed $dir"
    done
  '';
in
{
  imports = (import ../modules/home) ++ [
    ./homebrew.nix
    ./networking.nix
    ./network-audit.nix
    ./linux-builder.nix
    ../modules/editors/doom-emacs # declarative Doom Emacs (shared with NixOS)
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  system.checks.verifyNixPath = false;

  # Required by modern nix-darwin — tells it which user runs darwin-rebuild
  system.primaryUser = vars.user;

  # ── Nix Configuration ──────────────────────────────────────────────────
  # Determinate Nix owns the daemon and /etc/nix/nix.conf ("do not modify!"),
  # so nix-darwin's nix module stays disabled. Determinate's nix.conf ends with
  # `!include nix.custom.conf`, which we manage here. (With nix.enable = false,
  # nix-darwin's `nix.settings`/`nix.extraOptions` are NOT written — hence these
  # settings live in nix.custom.conf instead, where the daemon actually reads them.)
  nix.enable = false;

  environment.etc."nix/nix.custom.conf".text = ''
    # Managed by nix-darwin (darwin/default.nix); included by Determinate's nix.conf.
    trusted-users = root @admin ${vars.user}
    # Let Determinate's GC discard build-only outputs when space is needed.
    keep-outputs = false
    keep-derivations = true
    auto-optimise-store = true
    # Distributed builds for nixosTest / Linux derivations (see linux-builder.nix).
    builders = @/etc/nix/machines
    builders-use-substitutes = true
    # ── Build parallelism (same as NixOS) ──────────────────────────────
    max-jobs = auto
    cores = 0
    # ── Extra binary caches (same as NixOS; big win for emacs & co.) ───
    extra-substituters = https://nix-community.cachix.org
    extra-trusted-public-keys = nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=
  '';

  # ── Time zone (same as NixOS) ───────────────────────────────────────────
  time.timeZone = "Europe/Oslo";

  # ── PATH for GUI apps ───────────────────────────────────────────────────
  # Apps launched from Dock/Spotlight inherit launchd's minimal PATH and
  # can't see Nix tools (the Linux desktop has no such gap — everything
  # inherits the session env). Published via `launchctl setenv` at
  # activation; affects apps launched afterwards.
  launchd.user.envVariables.PATH =
    "/etc/profiles/per-user/${vars.user}/bin:/run/current-system/sw/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin";

  # Determinate Nixd handles disk-pressure GC. This weekly job also expires
  # profile generations older than 14 days, including root-owned system paths.
  launchd.daemons.nix-gc = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 14d"
      ];
      StartCalendarInterval = [{ Weekday = 0; Hour = 3; Minute = 0; }];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
      RunAtLoad = false;
    };
  };

  # A Nix build that is kept (--keep-failed) or killed leaves its folder in
  # /nix/var/nix/builds. The folders belong to build users, no garbage
  # collection removes them, and they held more than 35 GiB on 2026-11-12.
  # This hourly job removes them for every project on this machine.
  launchd.daemons.nix-build-sweep = {
    serviceConfig = {
      ProgramArguments = [ "${nixBuildSweep}" ];
      StartInterval = 3600;
      RunAtLoad = true;
      StandardOutPath = "/var/log/nix-build-sweep.log";
      StandardErrorPath = "/var/log/nix-build-sweep.log";
    };
  };

  # ── SOPS Secrets ────────────────────────────────────────────────────────
  # STAGED, not yet enabled: secrets.yaml is currently encrypted only to
  # admin_joel + host_main — this Mac's age key (the `mac_joel` anchor in
  # .sops.yaml, formerly mislabeled `admin_trive`) is NOT a recipient yet,
  # so enabling sops here would fail activation. To turn on:
  #   1. On the NixOS desktop:  sops updatekeys secrets/secrets.yaml
  #      (re-encrypts to all keys in .sops.yaml, including this Mac's)
  #   2. Uncomment sops-nix.darwinModules.sops in flake.nix
  #   3. Uncomment the block below (add emacs_authinfo → ~/.authinfo for
  #      parity with NixOS if wanted)
  # sops = {
  #   defaultSopsFile = ../secrets/secrets.yaml;
  #   defaultSopsFormat = "yaml";
  #   age.keyFile = "/Users/${vars.user}/.config/sops/age/keys.txt";
  #   age.sshKeyPaths = [];
  #   gnupg.sshKeyPaths = [];
  #
  #   secrets = {
  #     claude_key = {
  #       owner = vars.user;
  #     };
  #   };
  # };

  # ── Shells ──────────────────────────────────────────────────────────────
  programs.zsh.enable = true;
  environment = {
    shells = with pkgs; [ bash zsh ];
    pathsToLink = [ "/Applications" ];

    variables = {
      TERMINAL = "ghostty"; # macOS uses Ghostty (brew); vars.terminal=foot is Linux-only
      EDITOR = vars.editor;
      VISUAL = vars.editor;
    };

    # System packages (mirrors hosts/configuration.nix)
    systemPackages = with pkgs; [
      # Terminal (Ghostty comes from Homebrew cask on macOS)
      tmux
      bat
      btop
      coreutils
      git
      killall
      nix-tree
      wget
      nushell
      ranger

      # Build tools
      cmake
      gnumake

      # Editors & dev tools
      nixfmt
      shfmt
      shellcheck
      graphviz
      python3
      ispell
      nchat
      sqlite
      nil

      # File management
      rsync
      unzip
      unrar
      zip
      p7zip
      gnuplot

      # Encryption
      age
      libfido2

      # Tools
      uv

      # Claude Code (global on macOS)
      claude-code

      # OpenAI Codex CLI
      codex

      # Emacs comes from ../modules/editors/doom-emacs (declarative Doom,
      # emacs-macport with vterm + treesit baked in), along with base tools
      # (clang, fd, ripgrep, tree-sitter, emacs-lsp-booster, just, nil, …).

      # Web LSP servers (global; Rust/Go/etc. come from project devshells)
      nodejs_22
      bun
      typescript-language-server
      tailwindcss-language-server
      vscode-langservers-extracted
      astro-language-server

      vscode

      # Claude Code / agent workflow toolkit moved to
      # modules/home/agent-tools.nix (shared with NixOS).
    ];
  };

  # ── Fonts (same set as NixOS) ──────────────────────────────────────────
  fonts.packages = with pkgs; [
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.fira-code
    nerd-fonts.symbols-only # "Symbols Nerd Font Mono" — nerd-icons.el renders
                            # modeline/dired icons from this exact family;
                            # without it macOS shows tofu boxes (CoreText does
                            # no glyph fallback into other Nerd Fonts)
    source-code-pro
  ];

  # ── Users ───────────────────────────────────────────────────────────────
  users.users.${vars.user} = {
    name = vars.user;
    home = "/Users/${vars.user}";
  };

  # ── Security ────────────────────────────────────────────────────────────
  security.pam.services.sudo_local.touchIdAuth = true;

  # Custom CA certificate (same as NixOS for trive.ai VM)
  security.pki.certificates = [
    ''
      -----BEGIN CERTIFICATE-----
      MIICEjCCAbmgAwIBAgIUCwJufhGCR9vskIj786aC1kr6MmgwCgYIKoZIzj0EAwIw
      XzELMAkGA1UEBhMCTk8xDTALBgNVBAgMBE9zbG8xDTALBgNVBAcMBE9zbG8xFTAT
      BgNVBAoMDGRldnJhbmRvbS5jbzEbMBkGA1UEAwwSSm9lbCBKZXJvbWUgRFNvdXph
      MB4XDTI1MTEyNjEyMDUwM1oXDTM1MTEyNDEyMDUwM1owXzELMAkGA1UEBhMCTk8x
      DTALBgNVBAgMBE9zbG8xDTALBgNVBAcMBE9zbG8xFTATBgNVBAoMDGRldnJhbmRv
      bS5jbzEbMBkGA1UEAwwSSm9lbCBKZXJvbWUgRFNvdXphMFkwEwYHKoZIzj0CAQYI
      KoZIzj0DAQcDQgAEs85bPQY+6CS10BJR8CsUmzx0UPrC1/P66mm5w/2cpkiEwbol
      bw8Jr1D575GSgz3QfZVOkr/B6Bjc58N9DK8UiaNTMFEwHQYDVR0OBBYEFFkeBcPT
      169ewp12sWK+VI6ZCW+IMB8GA1UdIwQYMBaAFFkeBcPT169ewp12sWK+VI6ZCW+I
      MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDRwAwRAIgK7KlSmRZvtcUaie8
      D/hSdlgUk6zRf1bhhjUV7IhdhNkCIBB3yUQVjKXApXTCe5dTmq8GJnMFE0OgSMP9
      +qoUuFSO
      -----END CERTIFICATE-----
    ''
  ];

  # ── GPG Agent ───────────────────────────────────────────────────────────
  # nix-darwin's gnupg module has no pinentry option (unlike NixOS's
  # pinentryPackage), so the agent config file is managed via home-manager
  # below — pinentry-mac gives native GUI passphrase prompts + Keychain.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # ── macOS System Defaults ───────────────────────────────────────────────
  system.defaults = {
    finder = {
      AppleShowAllExtensions = true;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "clmv";
      FXEnableExtensionChangeWarning = false;   # Don't warn on extension changes
      QuitMenuItem = true;                       # Allow Cmd+Q in Finder
      ShowPathbar = true;
      ShowStatusBar = true;
    };
    dock = {
      autohide = true;
      autohide-delay = 0.0;              # No delay before dock appears
      autohide-time-modifier = 0.15;     # Fast dock animation
      mru-spaces = false;
      show-recents = false;
      launchanim = false;                 # Disable launch bounce animation
      minimize-to-application = true;
      mineffect = "scale";                # Faster than genie effect
      tilesize = 48;
      expose-animation-duration = 0.1;   # Speed up Mission Control animation
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
      AppleInterfaceStyle = "Dark";

      # ── Performance: Reduce animations ──
      NSAutomaticWindowAnimationsEnabled = false;  # Disable window open/close animations
      NSScrollAnimationEnabled = false;            # Disable smooth scrolling (snappier)
      NSWindowResizeTime = 0.001;                  # Near-instant window resize
      NSUseAnimatedFocusRing = false;              # Disable focus ring animation

      # ── Input responsiveness ──
      ApplePressAndHoldEnabled = false;    # Disable press-and-hold for key repeat
      "com.apple.swipescrolldirection" = true;     # Natural scrolling

      # ── Window management ──
      NSWindowShouldDragOnGesture = true;  # Move windows by holding anywhere (like Linux)
      AppleWindowTabbingMode = "always";   # Prefer tabs in all apps
      NSDisableAutomaticTermination = true; # Don't auto-terminate background apps

      # ── Text behavior ──
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
    };
    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
    screencapture = {
      location = "~/Screenshots";
      type = "png";
      disable-shadow = true;               # Cleaner screenshots, smaller files
    };
    CustomUserPreferences = {
      "com.apple.desktopservices" = {
        DSDontWriteNetworkStores = true;
        DSDontWriteUSBStores = true;
      };
      # Disable Finder animations
      "com.apple.finder" = {
        DisableAllAnimations = true;
      };
      # Speed up Quick Look panel
      "NSGlobalDomain" = {
        QLPanelAnimationDuration = 0;
      };
      # Reduce Mail.app animations
      # "com.apple.mail" = {
      # DisableReplyAnimations = true;
      # DisableSendAnimations = true;
      # };
      # Don't auto-rearrange Spaces based on recent use (already handled by dock.mru-spaces)
      "com.apple.dock" = {
        expose-group-apps = true;            # Group windows by app in Mission Control
      };
    };
  };

  # ── Nix Apps → /Applications (Spotlight-indexable) ──────────────────────
  # macOS Spotlight doesn't follow symlinks, so we use mkalias to create
  # real Finder aliases that Spotlight can index.
  system.activationScripts.applications.text = let
    env = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = [ "/Applications" ];
    };
  in
    pkgs.lib.mkForce ''
      echo "setting up Nix apps in /Applications..." >&2
      find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
      while read -r src; do
        app_name=$(basename "$src")
        echo "linking $src → /Applications/$app_name" >&2
        ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/$app_name"
      done
    '';

  # ── Doom Emacs ─────────────────────────────────────────────────────────
  # Fully declarative via ../modules/editors/doom-emacs (imported above):
  # nix-doom-emacs-unstraightened bakes Doom + doom.d into emacs-macport at
  # build time. The old clone + `doom sync` activation script is gone — it
  # silently failed (`2>/dev/null || true`) whenever a flake update bumped
  # Emacs, leaving packages compiled for the wrong Emacs version.

  # ── Home Manager ────────────────────────────────────────────────────────
  # Back up (don't abort on) any pre-existing dotfiles HM wants to manage,
  # e.g. a hand-written ~/.zprofile → ~/.zprofile.backup.
  home-manager.backupFileExtension = "backup";

  home-manager.users.${vars.user} = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;

    # GUI pinentry for gpg-agent (see GPG Agent section above)
    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program ${pkgs.pinentry_mac}/bin/pinentry-mac
    '';

  };

  system.stateVersion = 4;
}
