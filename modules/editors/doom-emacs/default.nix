# Doom Emacs: Personally not a fan of github:nix-community/nix-doom-emacs due to performance issues
#  This is an ideal way to install on a vanilla NixOS installion.
#  You will need to import this from somewhere in the flake (Obviously not in a home-manager nix file)
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ configuration.nix
#   └─ ./modules
#       └─ ./editors
#           ├─ default.nix
#           └─ ./emacs
#               └─ ./doom-emacs
#                   └─ default.nix *
#

# modules/editors/emacs/doom-emacs/default.nix
{ config, pkgs, vars, ... }:

{
  services.emacs.enable = true;
  system.userActivationScripts = {
    doomEmacs = {
      text = ''
        source ${config.system.build.setEnvironment}
        EMACS="$HOME/.emacs.d"
        DOOM="$HOME/.doom.d"

        # 1. Clone Doom if missing
        if [ ! -d "$EMACS" ]; then
          ${pkgs.git}/bin/git clone https://github.com/hlissner/doom-emacs.git $EMACS
          yes | $EMACS/bin/doom install
        fi

        # 2. Force link your config (Delete old symlink/dir first)
        #    Safeguard: verify vars.location exists before nuking
        if [ -d "${vars.location}/modules/editors/doom-emacs/doom.d" ]; then
           rm -rf $DOOM
           ln -s ${vars.location}/modules/editors/doom-emacs/doom.d $DOOM
        fi

        # 3. Sync: This ensures Doom recognizes the new binaries (LSPs) and 
        #    compiles your init.el changes.
        $EMACS/bin/doom sync
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # SYSTEM PACKAGES (Power Coder Suite)
  # ---------------------------------------------------------------------------
  environment.systemPackages = with pkgs; [
    clang
    coreutils
    fd
    git
    ripgrep
    ((emacs-pgtk.override { }).overrideAttrs (old:
      {
        # Add patches here if needed, otherwise this override block can be removed
      }))
    emacsPackages.treesit-auto

    nodejs_20
    typescript-language-server
    tailwindcss-language-server
    vscode-langservers-extracted

    # Astro support (try pkgs.astro-language-server first, fallback to nodePackages if missing)
    astro-language-server
    # nodePackages."@astrojs/language-server" # Uncomment if the above fails

    # -- 4. Extreme Performance --
    # The Rust-based JSON parser we configured in config.el
    emacs-lsp-booster
  ];
}
