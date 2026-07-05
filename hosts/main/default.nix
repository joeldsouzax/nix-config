{ config, pkgs, vars, ... }: {
  imports = [ ./hardware-configuration.nix ]
    ++ (import ../../modules/desktops/virtualisation);
  boot = {
    # Kernel 6.12 — proven-working with BOTH the NVIDIA proprietary driver and
    # the RTL8852AU WiFi (Archer TX20U Plus, via rtl8852au). Zen 7.0 COMPILED
    # both modules (CI-verified) but neither initialises/binds at runtime on
    # this hardware — 7.0 is too new for the 595 NVIDIA driver and the adapter.
    # Desktop fluidity comes from the Hyprland tuning instead, not the kernel.
    kernelPackages = pkgs.linuxPackages_6_12;
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
      # GTX 1070 is Pascal — NVIDIA moved Pascal to the 580 LEGACY branch; the
      # mainstream 595 (stable/production) driver IGNORES this GPU ("595.84 will
      # ignore this GPU" in dmesg). legacy_580 (580.159.04) supports it.
      # Pascal has no open kernel module, so `open = false` above is required.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
