# SSH Client Configuration
# Shared between NixOS and Darwin via home-manager
#
# Enables passwordless SSH between macOS laptop and NixOS desktop.
# Both machines use ed25519 keys; the config sets up named hosts for convenience.

{ lib, pkgs, vars, ... }:

{
  home-manager.users.${vars.user}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;  # We manage all defaults via matchBlocks."*"

    # Modern HM uses matchBlocks."*" for global SSH defaults
    matchBlocks = {
      # Global defaults for all hosts
      "*" = {
        identityFile = "~/.ssh/id_ed25519";
        addKeysToAgent = "yes";
        forwardAgent = true;
        extraOptions = lib.optionalAttrs pkgs.stdenv.isDarwin {
          # macOS Keychain integration (keeps passphrase across reboots)
          UseKeychain = "yes";
        };
      };

      # NixOS desktop — accessible from Mac via mDNS
      "desktop" = {
        hostname = "nixos.local";    # Avahi mDNS name
        user = vars.user;
      };

      # Trive dev VM — same on both platforms
      "trive-vm" = {
        hostname = "192.168.123.100";
        user = "trive";
      };

      # GitHub
      "github.com" = { };
    };
  };
}
