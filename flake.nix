{
  description = "nixos configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

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

    hyprland = { url = "git+https://github.com/hyprwm/Hyprland?submodules=1"; };

    hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };

  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, home-manager
    , home-manager-stable, hyprland, hyprspace, ... }:
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
        inherit inputs nixpkgs nixpkgs-stable home-manager hyprland hyprspace
          vars;
      });
    };
}
