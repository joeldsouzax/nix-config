{ config, pkgs, vars, ... }: {
  imports = [ ./hardware-configuration.nix ];
  boot = {
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
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware = {
    graphics = { enable = true; };
    nvidia = {
      modesetting.enable = true;
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
  environment = {
    systemPackages = with pkgs; [ discord rclone simple-scan slack ];
  };
  flatpak = {
    extraPackages = [ "com.github.tchx84.Flatseal" "com.stremio.Stremio" ];
  };
}
