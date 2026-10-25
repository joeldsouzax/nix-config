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
          # Kbuild supplies the certificates required by module aggregation.
          # The upstream install target only copies the unsigned module.
          makeFlags =
            old.makeFlags
            ++ previous.kernelModuleMakeFlags
            ++ [
              "INSTALL_MOD_PATH=${placeholder "out"}"
              "INSTALL_MOD_DIR=kernel/net/wireless/realtek/rtw89"
            ];
          installTargets = [ "modules_install" ];
          installFlags = [
            "-C"
            "${previous.kernel.dev}/lib/modules/${previous.kernel.modDirVersion}/build"
            "M=$(PWD)"
          ];
          # Mutate the module before Kbuild strips, signs and compresses it.
          preInstall = ''
            nuke-refs 8852au.ko
          '';
          postInstall = ''
            install -Dm755 suspend_rtw8852au "$out/usr/lib/systemd/system-sleep/suspend_rtw8852au"
          '';
          dontStrip = true;
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
