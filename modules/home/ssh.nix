# SSH Client Configuration
# Shared between NixOS and Darwin via home-manager.
#
# Trive work hosts (trive-vm, github.com-trive) are macOS-ONLY — the NixOS
# desktop never carries the Trive identity.

{ lib, pkgs, vars, ... }:

{
  home-manager.users.${vars.user}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false; # We manage all defaults via settings."*"

    settings = {
      # Global defaults for all hosts
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        addKeysToAgent = "yes";
        forwardAgent = true;
      } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        # macOS Keychain integration (keeps passphrase across reboots)
        UseKeychain = "yes";
      };

      # NixOS desktop over Tailscale (direct on the home LAN, relayed away from
      # it). Orca's `desktop` SSH target uses this alias.
      "desktop" = {
        hostname = vars.desktopHost;
        user = vars.user;
        forwardAgent = false;
      };
      "desktop-remote" = {
        hostname = vars.desktopHost;
        user = vars.user;
        forwardAgent = false;
      };

      # Avahi mDNS fallback for when Tailscale is down.
      "desktop-lan" = {
        hostname = "nixos.local";
        user = vars.user;
      };

      # GitHub — personal (joeldsouzax)
      "github.com" = { };
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      # ── Trive work (macOS only) ──────────────────────────────────────────
      "trive-vm" = {
        hostname = "192.168.123.100";
        user = "trive";
      };

      # IdentityAgent /dev/null forces SSH to read the key file from disk,
      # so the agent doesn't offer the personal key before the trive key.
      "github.com-trive" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/trive";
        identitiesOnly = true;
        IdentityAgent = "/dev/null";
      };
    };
  };
}
