{
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:
{
  imports = [
    ../main/hardware.nix
    ../main/performance.nix
    ../main/access.nix
    ../main/runner.nix
  ];

  # This is another profile for the same machine, with the same disks and SSH
  # identity. Existing NetworkManager connections and Joel's home stay in place.
  networking.hostName = "nixos";
  networking.firewall.allowedTCPPorts = lib.mkForce [ 22 ];
  networking.firewall.trustedInterfaces = lib.mkForce [ ];
  time.timeZone = "Europe/Oslo";
  i18n.defaultLocale = "en_US.UTF-8";
  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  users.users.${vars.user} = {
    isNormalUser = true;
    home = "/home/${vars.user}";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings.publish = {
      disable-publishing = false;
      publish-addresses = true;
    };
  };

  hardware.nvidia.nvidiaSettings = false;

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs-runner;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;
      min-free = 5 * 1024 * 1024 * 1024;
      max-free = 15 * 1024 * 1024 * 1024;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  services.journald.settings.Journal = {
    SystemMaxUse = "1G";
    SystemKeepFree = "2G";
    MaxRetentionSec = "14day";
  };

  environment.systemPackages = with pkgs; [
    codex
    git
    jq
    nano
  ];
}
