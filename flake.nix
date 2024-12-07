{
  description = "nixos configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #emacs overlay
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      flake = false;
    };
    # Nix-community doom emacs
    doom-emacs = {
      url = "github:nix-community/nix-doom-emacs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.emacs-overlay.follows = "emacs-overlay";
    };

    hyprland = { url = "git+https://github.com/hyprwm/Hyprland?submodules=1"; };

    hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };



    plasma-manager = {
      url = "github:pjones/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "nixpkgs";
    };
  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, nixos-hardware, home-manager
    , home-manager-stable, nixgl, doom-emacs, hyprland, hyprspace
    , plasma-manager, ... }:
    let
      vars = {
        user = "joel";
        location = "$HOME/.setup";
        terminal = "kitty";
        editor = "vim";
      };
    in {
      nixosConfigurations = (import ./hosts {
        inherit (nixpkgs) lib;
        inherit inputs nixpkgs nixpkgs-stable nixos-hardware home-manager
          doom-emacs hyprland hyprspace plasma-manager vars;
      });

      # homeConfigurations = (import ./home.nix {
      #   inherit (nixpkgs) lib;
      #   inherit inputs nixpkgs nixpkgs-stable home-manager nixgl vars;
      # });
    };
}
