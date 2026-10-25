{
  config,
  lib,
  pkgs,
  inputs,
  vars,
  ...
}:
{
  imports = [
    ../main/hardware.nix
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
    openssh.authorizedKeys.keyFiles = [ ../keys/joel-mac.pub ];
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
  services.openssh.enable = true;
  services.openssh.allowSFTP = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    settings.publish = {
      disable-publishing = false;
      publish-addresses = true;
    };
  };

  hardware.nvidia.nvidiaSettings = false;
  hardware.nvidia-container-toolkit.enable = true;
  systemd.sleep.settings.Sleep = {
    AllowSuspend = false;
    AllowHibernation = false;
    AllowHybridSleep = false;
    AllowSuspendThenHibernate = false;
  };

  nix = {
    registry.nixpkgs.flake = inputs.nixpkgs-runner;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      max-jobs = 1;
      cores = 4;
      auto-optimise-store = true;
      # Keep the existing administrator usable as an SSH Nix builder.
      trusted-users = [
        "root"
        vars.user
      ];
      min-free = 5 * 1024 * 1024 * 1024;
      max-free = 15 * 1024 * 1024 * 1024;
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
      flags = [
        "--filter"
        "until=168h"
      ];
    };
    daemon.settings = {
      log-driver = "local";
      log-opts = {
        max-size = "10m";
        max-file = "3";
      };
    };
  };
  services.journald.settings.Journal = {
    SystemMaxUse = "1G";
    SystemKeepFree = "2G";
    MaxRetentionSec = "14day";
  };

  users.groups.github-runner = { };
  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
    extraGroups = [
      "docker"
      "video"
      "render"
    ];
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/github-runner/work 0700 github-runner github-runner -"
    "d /var/lib/secrets 0700 root root -"
  ];

  services.github-runners.labcast = {
    enable = true;
    name = "labcast-desktop";
    url = "https://github.com/labcast/labcast-server";
    user = "github-runner";
    group = "github-runner";
    # Runtime secret; never copy a PAT into a Nix expression or the store.
    tokenFile = "/var/lib/secrets/github-runner-token";
    tokenType = "access";
    replace = true;
    extraLabels = [
      "nixos"
      "labcast-desktop"
    ];
    # /run is RAM-backed. Keep large builds on disk, outside registration state.
    workDir = "/var/lib/github-runner/work";
    extraPackages = with pkgs; [
      docker
      docker-compose
    ];
    extraEnvironment.CARGO_BUILD_JOBS = toString config.nix.settings.cores;
    serviceOverrides = {
      Restart = lib.mkForce "always";
      RestartSec = "30s";
      # Docker needs real group IDs and bind mounts visible on the host.
      PrivateUsers = false;
      PrivateTmp = false;
      ReadWritePaths = [
        "/tmp"
        "/var/tmp"
      ];
      # Native Studio tests need the GPU, too. Qualification is separate.
      PrivateDevices = false;
      # ProtectClock implies an RTC-only device allow-list. Capabilities and
      # the module's syscall filter still prohibit setting the system clock.
      ProtectClock = false;
    };
  };
  systemd.services.github-runner-labcast = {
    after = [ "docker.service" ];
    wants = [ "docker.service" ];
    # A network outage at boot must not permanently exhaust restart attempts.
    startLimitIntervalSec = 0;
  };

  environment.systemPackages = with pkgs; [
    codex
    git
    jq
    nano
    docker-compose
  ];
}
