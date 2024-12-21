{ inputs, nixpkgs, nixpkgs-stable, home-manager, hyprland, hyprspace, vars, ...
}:

let
  system = "x86_64-linux";
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
        mainMonitor = "DP-3";
        secondMonitor = "HDMI-A-1";
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
