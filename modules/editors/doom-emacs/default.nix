# Doom Emacs — fully declarative via nix-doom-emacs-unstraightened.
#
# Nix builds Doom + our ./doom.d config straight into the Emacs package, so
# `nixos-rebuild` yields a ready Emacs with every package compiled. There is
# NO git clone, NO `doom install`, and NO `doom sync` — ever. Doom itself is
# pinned by the flake input (bump it with `nix flake update`).
#
# The Emacs daemon (services.emacs) is wired to this Doom build automatically
# by the module (provideEmacs = true). To change your config, edit the elisp
# under doom.d/ and rebuild.
#
#  flake.nix → hosts/configuration.nix → modules/editors → this file
#
# NixOS-only (modules/editors isn't imported on Darwin), so emacs-pgtk is safe.

{ pkgs, vars, inputs, ... }:

{
  home-manager.users.${vars.user} = {
    imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

    programs.doom-emacs = {
      enable = true;

      # Our private Doom config (init.el / packages.el / config.el / lisp/*).
      doomDir = ./doom.d;

      # pgtk build → native Wayland, matches the Hyprland desktop.
      emacs = pkgs.emacs-pgtk;

      # Packages Doom won't pull on its own:
      #   vterm — the :term vterm module's compiled backend
      #   treesit-grammars — all grammars for treesit-based major modes
      extraPackages = epkgs: [
        epkgs.vterm
        epkgs.treesit-grammars.with-all-grammars
      ];
    };

    # Emacs daemon as a systemd user service. The unstraightened module sets
    # services.emacs.package to the Doom build above automatically.
    services.emacs.enable = true;
  };

  # ── System tooling Doom expects on PATH ───────────────────────────────
  # LSP servers, formatters, tree-sitter CLI and build tools, kept at system
  # level so the daemon and shells both find them. (Emacs itself now comes
  # from programs.doom-emacs above — no separate emacs package here.)
  environment.systemPackages = with pkgs; [
    # Base tools (doom doctor checks for these)
    clang
    coreutils
    fd
    git
    ripgrep

    # Language servers
    nodejs_22
    typescript-language-server
    tailwindcss-language-server
    vscode-langservers-extracted
    astro-language-server

    # Tree-sitter + perf helpers
    tree-sitter
    emacs-lsp-booster
    just
  ];
}
