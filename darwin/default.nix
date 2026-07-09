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
#           └─ ./networking.nix

{ config, lib, pkgs, inputs, vars, ... }:

let
  claude-code = pkgs.callPackage ../pkgs/claude-code.nix {};
in
{
  imports = (import ../modules/home) ++ [
    ./homebrew.nix
    ./networking.nix
    ./linux-builder.nix
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
    keep-outputs = true
    keep-derivations = true
    auto-optimise-store = true
    # Distributed builds for nixosTest / Linux derivations (see linux-builder.nix).
    builders = @/etc/nix/machines
    builders-use-substitutes = true
  '';

  # Determinate Nix ships no GC on macOS. Weekly collect-garbage + hardlink
  # optimise keeps the store lean. Runs as root so it can prune system paths.
  launchd.daemons.nix-gc = {
    serviceConfig = {
      ProgramArguments = [
        "/bin/sh"
        "-c"
        "/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 14d && /nix/var/nix/profiles/default/bin/nix store optimise"
      ];
      StartCalendarInterval = [{ Weekday = 0; Hour = 3; Minute = 0; }];
      StandardOutPath = "/var/log/nix-gc.log";
      StandardErrorPath = "/var/log/nix-gc.log";
      RunAtLoad = false;
    };
  };

  # ── SOPS Secrets (disabled — using local Qwen via MLX, no API keys needed)
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

      # Emacs with treesit + vterm (emacsMacport for native macOS keyboard/UI)
      ((emacs-macport.pkgs.withPackages
        (epkgs: [ epkgs.vterm epkgs.treesit-grammars.with-all-grammars ])))

      # Doom Emacs LSP support (same as NixOS modules/editors/doom-emacs)
      nodejs_22
      typescript-language-server
      tailwindcss-language-server
      vscode-langservers-extracted
      astro-language-server
      tree-sitter
      emacs-lsp-booster
      just

      # Doom base tools
      clang
      fd
      ripgrep

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
  # Emacs is now installed via Nix (environment.systemPackages above).
  # LSP tools and base Doom tools are also in systemPackages.

  # Clone + sync Doom Emacs on activation (runs as root, uses sudo -u for user ops)
  system.activationScripts.postActivation.text = ''
    echo "Setting up Doom Emacs for ${vars.user}..."
    USER_HOME="/Users/${vars.user}"
    EMACS="$USER_HOME/.emacs.d"
    DOOM="$USER_HOME/.doom.d"
    DOOM_SRC="$USER_HOME/.setup/modules/editors/doom-emacs/doom.d"

    if [ ! -d "$EMACS" ]; then
      sudo -u ${vars.user} ${pkgs.git}/bin/git clone https://github.com/hlissner/doom-emacs.git "$EMACS"
      sudo -u ${vars.user} yes | sudo -u ${vars.user} "$EMACS/bin/doom" install
    fi

    if [ -d "$DOOM_SRC" ]; then
      sudo -u ${vars.user} rm -rf "$DOOM"
      sudo -u ${vars.user} ln -s "$DOOM_SRC" "$DOOM"
    fi

    sudo -u ${vars.user} "$EMACS/bin/doom" sync 2>/dev/null || true
  '';

  # ── Home Manager ────────────────────────────────────────────────────────
  # Back up (don't abort on) any pre-existing dotfiles HM wants to manage,
  # e.g. a hand-written ~/.zprofile → ~/.zprofile.backup.
  home-manager.backupFileExtension = "backup";

  home-manager.users.${vars.user} = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
  };

  system.stateVersion = 4;
}
