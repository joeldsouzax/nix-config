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

  # ---------------------------------------------------------------------------
  # DOOM EMACS INSTALLATION / SYNC
  # ---------------------------------------------------------------------------
  # NOTE: 'system.userActivationScripts' is likely a custom option in your flake.
  # If this runs as root (standard NixOS), $HOME will be /root.
  # Ensure this script runs as YOUR user.
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
    # -- 1. Base Tools --
    clang
    coreutils
    fd
    git
    ripgrep

    # -- 2. Emacs 29+ (REQUIRED for Tree-sitter & Performance) --
    # Use 'emacs-pgtk' if on Wayland, 'emacs-mac' if on macOS, otherwise 'emacs29'
    ((emacs29.override { withTreeSitter = true; }).overrideAttrs (old:
      {
        # Optional: Add specific patches here if needed
      }))
    emacsPackages.treesit-auto

    # -- 3. The "Power Coder" Web Stack (Global) --
    # Replaces 'npm i -g ...'
    nodejs_20 # Runtime for most LSPs
    typescript-language-server # TS/JS Support
    tailwindcss-language-server # Tailwind Support
    vscode-langservers-extracted # HTML/CSS/JSON/ESLint

    # Astro support (try pkgs.astro-language-server first, fallback to nodePackages if missing)
    astro-language-server
    # nodePackages."@astrojs/language-server" # Uncomment if the above fails

    # -- 4. Extreme Performance --
    # The Rust-based JSON parser we configured in config.el
    emacs-lsp-booster
  ];
}
