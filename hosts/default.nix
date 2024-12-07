{ inputs, nixpkgs, nixpkgs-stable, nixos-hardware, home-manager, doom-emacs
, hyprland, hyprspace, plasma-manager, vars, ... }:

let
  system = "x86_64-linux";
  pkgs = import nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  stable = import nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };

  lib = nixpkgs.lib;
in {
  main = lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system stable hyprland hyprspace vars;
      host = {
        hostname = "main";
        mainMonitor = "HDMI-A-1";
        secondMonitor = "reader";
      };
    };
    modules = [
      ./main
      ./configuration.nix
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];
  };
}
