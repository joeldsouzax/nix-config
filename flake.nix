{
  description = "nixos configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nur = { url = "github:nix-community/NUR"; };

    nixgl = {
      url = "github:guibou/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #emacs overlay
    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      flake = false;
    };

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

    ## mac
    ##

    # nix-darwin.url = "github:LnL7/nix-darwin";
    # nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    # nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    # homebrew-core = {
    #   url = "github:homebrew/homebrew-core";
    #   flake = false;
    # };
    # homebrew-cask = {
    #   url = "github:homebrew/homebrew-cask";
    #   flake = false;
    # };
    # homebrew-bundle = {
    #   url = "github:homebrew/homebrew-bundle";
    #   flake = false;
    # };
    # emacs-plus = {
    #   url = "github:d12frosted/homebrew-emacs-plus";
    #   flake = false;
    # };

  };
  outputs = inputs@{ self, nixpkgs, nixpkgs-stable, home-manager
    , home-manager-stable, nur, doom-emacs, hyprland, hyprspace,
    #   nix-darwin
    # , nix-homebrew, homebrew-core, homebrew-cask, homebrew-bundle, emacs-plus
    ... }:
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
        inherit inputs nixpkgs nixpkgs-stable home-manager nur doom-emacs
          hyprland hyprspace vars;
      });

      # darwinConfiguration = (import ./darwin {
      #   inherit self nix-darwin home-manager nix-homebrew homebrew-core
      #     homebrew-cask homebrew-bundle emacs-plus;
      # });
    };
}
