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

    taps = [
      "nikitabobko/tap"       # Required for aerospace WM
    ];

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
      "utm"
      "spotify"
    ];

    # ── CLI Tools (Brews) ───────────────────────────────────────────────
    brews = [
      "pinentry-mac"
      "qemu"
      "libvirt"
      "dnsmasq"
      "nginx"
    ];

    # Mac App Store apps
    masApps = { };
  };
}
