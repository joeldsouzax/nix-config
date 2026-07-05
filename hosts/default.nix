{ inputs, nixpkgs, nixpkgs-stable, home-manager, nur, doom-emacs, hyprland
, hyprspace, sops-nix, vars, ... }:

let
  system = "x86_64-linux";
  stable = import nixpkgs-stable {
    inherit system;
    config.allowUnfree = true;
  };

  lib = nixpkgs.lib;
in {
  main = lib.nixosSystem {
    # Platform is set via nixpkgs.hostPlatform in hardware-configuration.nix
    # Do NOT pass `system` here — it's deprecated and triggers warnings
    specialArgs = {
      inherit inputs stable hyprland hyprspace vars sops-nix;
      host = {
        hostname = "main";
        mainMonitor = "DP-3";
      };
    };
    modules = [
      nur.modules.nixos.default
      ./main
      ./configuration.nix
      sops-nix.nixosModules.sops
      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
      }
    ];
  };
}
