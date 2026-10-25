{ pkgs, ... }: {
  imports = [
    ./hardware.nix
    ./performance.nix
    ./access.nix
    ./runner.nix
  ]
  ++ (import ../../modules/desktops/virtualisation);
  services.xserver.enable = true;
  services.pcscd.enable = true;
  hardware = {
    nvidia.nvidiaSettings = true;
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

  environment = {
    systemPackages = with pkgs; [
      brightnessctl
      rclone
      simple-scan
      slack
    ];
  };
  flatpak = {
    extraPackages = [
      "com.github.tchx84.Flatseal"
      "com.stremio.Stremio"
    ];
  };
}
