{ config, pkgs, vars, ... }: {
  imports = [ ./hardware-configuration.nix ]
    ++ (import ../../modules/desktops/virtualisation);
  boot = {
    # Zen kernel: desktop-tuned scheduler/timers for interactivity & low latency.
    # WiFi (RTL8852AU) works via the morrownr/rtw89 out-of-tree module built
    # against Zen — see boot.extraModulePackages in hardware-configuration.nix.
    # (The old lwfinger rtl8852au driver is dead and broken on Zen.)
    kernelPackages = pkgs.linuxPackages_zen;
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
    graphics = {
      enable = true;
      extraPackages = [ pkgs.libvdpau-va-gl ];
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = true;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      # Keep the driver resident so GPU init latency doesn't hit every process
      # (helps app/terminal launch and Wayland compositor responsiveness).
      nvidiaPersistenced = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    sane = {
      enable = true;
      extraBackends = [ pkgs.sane-airscan ];
    };
  };

  hyprland.enable = true;

  # `programs.light`/`pkgs.light` were removed from nixpkgs (unmaintained).
  # brightnessctl is the maintained replacement; its udev rules grant the
  # video group backlight access (used by the WM brightness keybinds).
  services.udev.packages = [ pkgs.brightnessctl ];

  environment = { systemPackages = with pkgs; [ brightnessctl rclone simple-scan slack ]; };
  flatpak = {
    extraPackages = [ "com.github.tchx84.Flatseal" "com.stremio.Stremio" ];
  };
}

#TODO: fix the nvidia drive
