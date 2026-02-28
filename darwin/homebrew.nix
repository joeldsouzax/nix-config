# Homebrew Configuration for macOS
# Manages apps that work better as native macOS bundles or aren't in nixpkgs
#
# Mirrors the NixOS approach:
#   NixOS: flatpak + environment.systemPackages
#   Darwin: homebrew casks + brews

{ pkgs, ... }:

{
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };

    global.autoUpdate = false;

    # ── GUI Applications (Casks) ────────────────────────────────────────
    casks = [
      # Browsers (mirrors NixOS: firefox + google-chrome)
      "google-chrome"
      "firefox"

      # Communication (mirrors NixOS: slack from systemPackages)
      "discord"
      "slack"
      "telegram"

      # Development
      "figma"                # NixOS has figma-linux

      # Media (mirrors NixOS: vlc via flatpak)
      "vlc"

      # Terminal
      "ghostty"              # GPU-accelerated terminal (Nix pkg is Linux-only)

      # Window Management (replaces Hyprland)
      "aerospace"            # Tiling WM for macOS

      # Display management
      "betterdisplay"

      # Security (mirrors NixOS: 1password)
      "1password"
      "1password-cli"

      # Virtualization (for `just up` VM management)
      "utm"                  # QEMU frontend with native macOS UI
    ];

    # ── CLI Tools (Brews) ───────────────────────────────────────────────
    brews = [
      # Emacs (mirrors NixOS: emacs-pgtk via nixpkgs)
      {
        name = "emacs-plus@31";
        args = [ "with-dbus" "with-imagemagick" "with-mailutils" "with-native-comp" ];
      }
      "pinentry-mac"

      # Build deps for emacs native-comp
      "gcc"
      "libgccjit"
      "libtool"

      # Virtualization (for libvirt + QEMU backend)
      # `just up` uses terraform + libvirt provider → needs these
      "qemu"
      "libvirt"

      # DNS resolution for *.trive.ai (see networking.nix)
      "dnsmasq"

      # TLS passthrough proxy (mirrors NixOS nginx stream config)
      "nginx"
    ];

    # Mac App Store apps
    masApps = { };
  };
}
