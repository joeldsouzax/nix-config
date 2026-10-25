{ pkgs, config }:
let
  inherit (pkgs) lib;
  runners = lib.attrValues (
    lib.filterAttrs (_: runner: runner.enable) config.services.github-runners
  );
  service = config.systemd.services.github-runner-labcast;
  checks = {
    headless =
      !config.services.xserver.enable
      && !config.services.displayManager.enable
      && !config.programs.hyprland.enable;
    oneRunner = builtins.length runners == 1;
    separateAccount = lib.all (
      runner:
      runner.user != null
      && runner.user != "root"
      && config.users.users.${runner.user}.isSystemUser
      && !(builtins.elem "wheel" config.users.users.${runner.user}.extraGroups)
    ) runners;
    diskWork = lib.all (
      runner: runner.workDir != null && lib.hasPrefix "/var/lib/" runner.workDir
    ) runners;
    runtimeSecret = lib.all (
      runner: runner.tokenFile != null && !(lib.hasPrefix "/nix/store/" (toString runner.tokenFile))
    ) runners;
    bootService =
      builtins.elem "multi-user.target" service.wantedBy && service.serviceConfig.Restart == "always";
    noSleep =
      !config.systemd.sleep.settings.Sleep.AllowSuspend
      && !config.systemd.sleep.settings.Sleep.AllowHibernation;
    boundedBuilds = config.nix.settings.max-jobs == 1 && config.nix.settings.cores <= 4;
    adminAccess = config.services.openssh.enable && config.networking.networkmanager.enable;
    nativeDevices = !service.serviceConfig.PrivateDevices && !service.serviceConfig.ProtectClock;
    dockerMounts =
      !service.serviceConfig.PrivateUsers
      && !service.serviceConfig.PrivateTmp
      && builtins.elem "/tmp" service.serviceConfig.ReadWritePaths
      && builtins.elem "/var/tmp" service.serviceConfig.ReadWritePaths;
    narrowFirewall =
      config.networking.firewall.allowedTCPPorts == [ 22 ]
      && config.networking.firewall.trustedInterfaces == [ ];
  };
  failures = lib.attrNames (lib.filterAttrs (_: passed: !passed) checks);
in
assert lib.assertMsg (
  failures == [ ]
) "Runner profile failed: ${lib.concatStringsSep ", " failures}";
# Force NixOS's own option checks and assertions, too. This is a configuration
# check, not evidence that registration, Docker or GPU jobs work on the host.
builtins.deepSeq config.system.build.toplevel.drvPath (
  pkgs.runCommand "runner-configuration" { } ''
    touch "$out"
  ''
)
