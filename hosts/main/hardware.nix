{ config, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Both profiles use this kernel series for RTL8852AU Wi-Fi and the GTX 1070.
  boot = {
    kernelPackages = pkgs.linuxPackages_6_12.extend (
      _: previous: {
        rtl8852au = previous.rtl8852au.overrideAttrs (old: {
          # Linux 6.12.101 backported the monitor-channel callback change.
          patches = old.patches ++ [ ../../pkgs/rtl8852au-monitor.patch ];
        });
      }
    );
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
