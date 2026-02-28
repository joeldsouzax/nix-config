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
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  system.checks.verifyNixPath = false;

  # Required by modern nix-darwin — tells it which user runs darwin-rebuild
  system.primaryUser = vars.user;

  # ── Nix Configuration ──────────────────────────────────────────────────
  nix = {
    enable = true;
    settings = {
      trusted-users = [ "@admin" vars.user ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs        = true
      keep-derivations     = true
    '';
  };

  # ── Shells ──────────────────────────────────────────────────────────────
  programs.zsh.enable = true;
  environment = {
    shells = with pkgs; [ bash zsh ];
    pathsToLink = [ "/Applications" ];

    variables = {
      TERMINAL = vars.terminal;
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

      # Doom Emacs LSP support (same as NixOS modules/editors/doom-emacs)
      nodejs_20
      typescript-language-server
      tailwindcss-language-server
      vscode-langservers-extracted
      nodePackages."@astrojs/language-server"
      tree-sitter
      emacs-lsp-booster
      just

      # Doom base tools
      clang
      fd
      ripgrep
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
      "com.apple.mail" = {
        DisableReplyAnimations = true;
        DisableSendAnimations = true;
      };
      # Don't auto-rearrange Spaces based on recent use (already handled by dock.mru-spaces)
      "com.apple.dock" = {
        expose-group-apps = true;            # Group windows by app in Mission Control
      };
    };
  };

  # ── Doom Emacs (via Homebrew emacs-plus) ────────────────────────────────
  # Emacs-plus comes from Homebrew (see homebrew.nix).
  # LSP tools and base Doom tools are included in environment.systemPackages above.

  # Clone + sync Doom Emacs on activation (runs as root, uses sudo -u for user ops)
  system.activationScripts.postActivation.text = ''
    echo "Setting up Doom Emacs for ${vars.user}..."
    USER_HOME="/Users/${vars.user}"
    EMACS="$USER_HOME/.emacs.d"
    DOOM="$USER_HOME/.doom.d"

    if [ ! -d "$EMACS" ]; then
      sudo -u ${vars.user} ${pkgs.git}/bin/git clone https://github.com/hlissner/doom-emacs.git "$EMACS"
      sudo -u ${vars.user} yes | sudo -u ${vars.user} "$EMACS/bin/doom" install
    fi

    if [ -d "${vars.location}/modules/editors/doom-emacs/doom.d" ]; then
      sudo -u ${vars.user} rm -rf "$DOOM"
      sudo -u ${vars.user} ln -s "${vars.location}/modules/editors/doom-emacs/doom.d" "$DOOM"
    fi

    sudo -u ${vars.user} "$EMACS/bin/doom" sync 2>/dev/null || true
  '';

  # ── Home Manager ────────────────────────────────────────────────────────
  home-manager.users.${vars.user} = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
  };

  system.stateVersion = 4;
}
