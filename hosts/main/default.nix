{ config, pkgs, vars, ... }: {
  imports = [ ./hardware-configuration.nix ]
    ++ (import ../../modules/desktops/virtualisation);
  boot = {
    # kernelPackages = pkgs.linuxPackages_6_10;
    kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 3;
      };
      efi = { canTouchEfiVariables = true; };
      timeout = 5;
    };
  };
  nixpkgs.config.nvidia.acceptLicense = true;
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.pcscd.enable = true;
  hardware = {
    graphics = { enable = true; };
    nvidia = {
      # modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };

  hyprland.enable = true;
  programs.light.enable = true;

  environment = { systemPackages = with pkgs; [ rclone simple-scan slack ]; };
  flatpak = {
    extraPackages = [ "com.github.tchx84.Flatseal" "com.stremio.Stremio" ];
  };
}

#TODO: fix the nvidia driver
