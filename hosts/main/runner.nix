{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [ ../../modules/desktops/virtualisation/docker.nix ];

  hardware.nvidia-container-toolkit.enable = true;
  virtualisation.docker = {
    autoPrune = {
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
    url = "https://github.com/labcast";
    # Runner updates stay independent of desktop and Mac package updates.
    package = inputs.nixpkgs-runner.legacyPackages.${pkgs.stdenv.hostPlatform.system}.github-runner;
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
}
