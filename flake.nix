{
  description = "NixOS + nix-darwin configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nur = {
      url = "github:nix-community/NUR";
    };

    # nixgl = {
    #   url = "github:guibou/nixGL";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

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

    hyprland = {
      url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    };

    hyprspace = {
      url = "github:KZDKM/Hyprspace";
      inputs.hyprland.follows = "hyprland";
    };

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Declarative Doom Emacs — builds Doom + our doom.d fully in Nix (no
    # `doom sync`). Successor to nix-doom-emacs; uses Doom's real package
    # manager, so no straight.el performance penalty. follows="" = don't
    # fetch a second nixpkgs (the module/overlay don't use it).
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };

    # AGS v2 / Astal — GJS widget framework for the desktop monitoring dashboard.
    ags = {
      url = "github:aylur/ags";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      home-manager-stable,
      nur,
      doom-emacs,
      hyprland,
      hyprspace,
      nix-darwin,
      sops-nix,
      ...
    }:
    let
      vars = {
        user = "joel";
        location = "$HOME/.setup";
        terminal = "foot";
        editor = "nano";
      };
    in
    {
      nixosConfigurations = (
        import ./hosts {
          inherit (nixpkgs) lib;
          inherit
            inputs
            nixpkgs
            nixpkgs-stable
            home-manager
            nur
            doom-emacs
            hyprland
            hyprspace
            sops-nix
            vars
            ;
        }
      );

      darwinConfigurations."joel" = nix-darwin.lib.darwinSystem {
        modules = [
          ./darwin
          # sops-nix.darwinModules.sops  # disabled — using local Qwen via MLX
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          }
        ];
        specialArgs = {
          inherit inputs vars;
          stable = import nixpkgs-stable {
            system = "aarch64-darwin";
            config.allowUnfree = true;
          };
        };
      };

      # ── Integration tests (nixosTest) ──────────────────────────────────────
      # Full NixOS guest VMs. These are Linux derivations, so on the Mac they
      # offload to a Linux builder (see darwin/linux-builder.nix):
      #   nix build .#checks.x86_64-linux.integration -L   # → desktop (KVM)
      #   nix build .#checks.aarch64-linux.integration -L  # → local builder VM
      checks =
        let
          mkTest = system:
            (import nixpkgs { inherit system; }).testers.runNixOSTest ./tests/integration.nix;
        in
        {
          x86_64-linux.integration = mkTest "x86_64-linux";
          aarch64-linux.integration = mkTest "aarch64-linux";
        };

      # ── Packages ───────────────────────────────────────────────────────────
      # Kernel modules built against the Zen kernel, exposed so CI can prove they
      # actually COMPILE against Zen before the desktop rebuilds (the toplevel
      # eval/CI does NOT build kernel modules, so a kmod build failure would
      # otherwise only surface at `nixos-rebuild`):
      #   nix build .#packages.x86_64-linux.rtw89-morrownr -L      # WiFi
      #   nix build .#packages.x86_64-linux.nvidia-zen-stable -L   # NVIDIA 595
      #   nix build .#packages.x86_64-linux.nvidia-zen-latest -L   # NVIDIA 610
      packages.x86_64-linux =
        let
          linuxPkgs = (import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          }).linuxPackages_zen;
        in
        {
          rtw89-morrownr = linuxPkgs.callPackage ./pkgs/rtw89-morrownr.nix { };
          nvidia-zen-stable = linuxPkgs.nvidiaPackages.stable;
          nvidia-zen-latest = linuxPkgs.nvidiaPackages.latest;
        };
    };
}
