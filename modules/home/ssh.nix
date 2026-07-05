# SSH Client Configuration
# Shared between NixOS and Darwin via home-manager.
#
# Trive work hosts (trive-vm, github.com-trive) are macOS-ONLY — the NixOS
# desktop is for devrandom work only.

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
      } // lib.optionalAttrs pkgs.stdenv.isDarwin {
        # macOS Keychain integration (keeps passphrase across reboots)
        UseKeychain = "yes";
      };

      # NixOS desktop — accessible from Mac via mDNS
      "desktop" = {
        hostname = "nixos.local"; # Avahi mDNS name
        user = vars.user;
      };

      # GitHub — personal (joeldsouzax)
      "github.com" = { };
    }
    // lib.optionalAttrs pkgs.stdenv.isDarwin {
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
