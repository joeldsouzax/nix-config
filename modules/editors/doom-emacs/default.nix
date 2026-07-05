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

  # ── Editor tooling on PATH (global) ───────────────────────────────────
  # Philosophy: every project is a flake + direnv, so per-project language
  # servers (rust-analyzer, cargo, tsserver, gopls, …) come from the project's
  # devshell — NOT from here. Only truly global things live at system level:
  #   1. editor infrastructure Doom needs everywhere
  #   2. Nix tooling — you edit Nix files (this repo!) outside any project
  #      flake, so nil + formatters must be globally available.
  # Emacs itself comes from programs.doom-emacs above.
  environment.systemPackages = with pkgs; [
    # Editor infrastructure (doom doctor checks for these)
    clang            # native-comp / cc
    coreutils
    fd
    git
    ripgrep
    tree-sitter
    emacs-lsp-booster
    just             # generic task runner

    # Nix tooling — global on purpose (Nix editing happens outside devshells)
    nil              # Nix language server (configured in doom.d/config.el)
    alejandra        # Nix formatter (configured in doom.d/config.el)
    nixfmt-rfc-style # alternative Nix formatter
  ];
}
