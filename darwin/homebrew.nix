# Homebrew Configuration for macOS
# Manages apps that work better as native macOS bundles or aren't in nixpkgs
#
# Mirrors the NixOS approach:
#   NixOS: flatpak + environment.systemPackages
#   Darwin: homebrew casks + brews

{ pkgs, vars, ... }:

{
  # ── Homebrew 6.0 tap-trust opt-out ──────────────────────────────────────
  # Homebrew 6.0 made `brew trust` checks default-on for non-official taps
  # (env_config.rb: "This is the default unless $HOMEBREW_NO_REQUIRE_TAP_TRUST
  # is set"). That deadlocks nix-darwin activation, which runs
  # `brew bundle --force-cleanup` (see the generated activate script):
  #
  #   1. --force-cleanup deletes ~/.homebrew/trust.json outright
  #   2. the `brew cleanup` it then invokes refuses nikitabobko/tap as
  #      untrusted and exits 1
  #   3. activation aborts *before* home-manager runs — so every unrelated
  #      change (Emacs, shell, …) silently fails to apply
  #
  # `brew trust` cannot break the loop: cask- and tap-level entries are both
  # wiped by step 1. Activation runs brew via `sudo --preserve-env=PATH`, so
  # only PATH survives — env must reach Homebrew through its own brew.env,
  # which brew reads itself. Verified: without this file activation exits 1,
  # with it exits 0.
  home-manager.users.${vars.user}.home.file.".homebrew/brew.env".text = ''
    HOMEBREW_NO_REQUIRE_TAP_TRUST=1
  '';

  homebrew = {
    enable = true;

    taps = [
      "nikitabobko/tap"       # Required for aerospace WM
      "can1357/tap"           # oh-my-pi (omp) — Rust-core AI coding agent
      "stablyai/orca"         # Orca agent workspace
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
      "stablyai/orca/orca"    # Primary workspace for projects and coding agents

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
      "omp"                  # oh-my-pi — terminal AI coding agent (Rust core + TS harness)
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
