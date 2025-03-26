{ self, nix-darwin, home-manager, nix-homebrew, homebrew-core, homebrew-cask
, homebrew-bundle, emacs-plus, ... }: {
  darwinConfigurations."joel" = nix-darwin.lib.darwinSystem {

    modules = [
      ./modules/darwin
      home-manager.darwinModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.joeldsouza.imports = [ ./modules/home-manager ];
        };
      }
      nix-homebrew.darwinModules.nix-homebrew
      {
        nix-homebrew = {
          # Install Homebrew under the default prefix
          enable = true;
          # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
          enableRosetta = true;
          # User owning the Homebrew prefix
          user = "joeldsouza";
          # Optional: Declarative tap management
          # taps = {
          #   "homebrew/homebrew-core" = homebrew-core;
          #   "homebrew/homebrew-cask" = homebrew-cask;
          #   "homebrew/homebrew-bundle" = homebrew-bundle;
          #   "d12frosted/homebrew-emacs-plus" = emacs-plus;
          # };

          # Optional: Enable fully-declarative tap management
          #
          # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
          mutableTaps = false;
        };
      }
    ];

    darwinPackages = self.darwinConfigurations."joel".pkgs;
  };
}
