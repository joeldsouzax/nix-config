{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Both profiles use this kernel series for RTL8852AU Wi-Fi and the GTX 1070.
  boot = {
    kernelPackages = pkgs.linuxPackages_6_12.extend (
      final: _: {
        rtw89-morrownr = final.callPackage ../../pkgs/rtw89-morrownr.nix { };
      }
    );
    extraModulePackages = [ config.boot.kernelPackages.rtw89-morrownr ];
    # Prevent another driver from claiming the same USB adapter during testing
    # or after a kernel update. The working rtl8xxxu spare remains independent.
    blacklistedKernelModules = [
      "8852au"
      "rtw89_8852au"
    ];
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
