{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # This kernel series works with the desktop's RTL8852AU Wi-Fi and GTX 1070.
  boot = {
    kernelPackages = pkgs.linuxPackages_6_12;
    kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi.canTouchEfiVariables = true;
      timeout = 5;
    };
  };

  nixpkgs.config.nvidia.acceptLicense = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    # Pascal requires the closed driver from the 580 legacy series.
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
    nvidiaPersistenced = true;
  };
}
