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
    # -- Base Tools --
    clang
    coreutils
    fd
    git
    ripgrep

    # -- Emacs with Grammar Injection --
    ((emacs-pgtk.pkgs.withPackages (epkgs: [
      epkgs.vterm
      epkgs.treesit-grammars.with-all-grammars

      # Explicitly add Astro and TSX/Typescript to be absolutely safe
      epkgs.treesit-grammars.tree-sitter-astro
      epkgs.treesit-grammars.tree-sitter-tsx
      epkgs.treesit-grammars.tree-sitter-typescript
      epkgs.treesit-grammars.tree-sitter-json
      epkgs.treesit-grammars.tree-sitter-css
    ])))

    # -- Language Servers --
    nodejs_20
    typescript-language-server
    tailwindcss-language-server
    vscode-langservers-extracted

    # Use nodePackages for Astro LS if the top-level one is missing
    nodePackages."@astrojs/language-server"

    # -- Fallback Builder Tools (Power Coder Safety Net) --
    # If a grammar is EVER missing from Nix, these allow Doom to 
    # auto-compile it via 'M-x treesit-install-language-grammar'
    tree-sitter
    gcc
    emacs-lsp-booster
  ];
}
