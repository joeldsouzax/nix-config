# Doom Emacs — fully declarative via nix-doom-emacs-unstraightened.
#
# Nix builds Doom + our ./doom.d config straight into the Emacs package, so
# a rebuild yields a ready Emacs with every package compiled. There is
# NO git clone, NO `doom install`, and NO `doom sync` — ever. Doom itself is
# pinned by the flake input (bump it with `nix flake update`).
#
# Cross-platform:
#   Linux  → emacs-pgtk (native Wayland, matches Hyprland) + systemd daemon
#   Darwin → emacs-macport (native macOS keyboard/UI); the final package
#            ships Emacs.app wired to the Doom build, no daemon needed
#
#  flake.nix → hosts/configuration.nix → modules/editors → this file  (NixOS)
#  flake.nix → darwin/default.nix → this file                        (macOS)

{ config, lib, pkgs, vars, inputs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
  # Doom's (spell +flyspell) shells out to aspell; it must carry its
  # dictionaries (a bare `aspell`/`ispell` binary finds none on Nix).
  # nixpkgs removed the computer/science add-ons after their upstreams vanished.
  aspell = pkgs.aspellWithDicts (ds: [ ds.en ]);
in
{
  home-manager.users.${vars.user} = {
    imports = [ inputs.nix-doom-emacs-unstraightened.homeModule ];

    programs.doom-emacs = {
      enable = true;

      # Our private Doom config (init.el / packages.el / config.el / lisp/*).
      doomDir = ./doom.d;

      emacs = if isDarwin then pkgs.emacs-macport else pkgs.emacs-pgtk;

      # Packages Doom won't pull on its own:
      #   vterm — the :term vterm module's compiled backend
      #   treesit-grammars — all grammars for treesit-based major modes
      extraPackages = epkgs: [
        epkgs.vterm
        epkgs.treesit-grammars.with-all-grammars
      ];
    } // lib.optionalAttrs isDarwin {
      # macOS GUI apps launched from Dock/Spotlight get launchd's minimal
      # PATH (no /run/current-system/sw/bin), so anything Emacs must find
      # regardless of launch method is baked into the wrapper's PATH here.
      # Setting this replaces the option's default of [ git ripgrep fd ].
      extraBinPackages = with pkgs; [
        git
        ripgrep
        fd
        # :tools direnv shells out to this binary; without it no project
        # devshell ever loads and every per-project LSP (rust-analyzer,
        # gopls, tsserver…) fails with "<server> starting exited".
        # `nix` is deliberately NOT here: Determinate Nix owns the daemon
        # (nix.enable = false) — a nixpkgs client would shadow it. Its
        # profile dir is prepended in doom.d/config.el instead.
        direnv
        coreutils-prefixed # gls — dired needs GNU `ls --dired`; BSD ls breaks it
        emacs-lsp-booster
        nil
        alejandra
        nixfmt
        aspell # spell-checking (:checkers spell)
      ];
    };

    # Emacs daemon on both platforms — systemd user service on Linux,
    # launchd agent on macOS (verified: macport daemon + emacsclient frames
    # work). The unstraightened module sets services.emacs.package to the
    # Doom build automatically. `ec` (shell alias) opens instant client
    # frames; Emacs.app remains available for standalone use.
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
    nixfmt           # alternative Nix formatter (RFC style)

    aspell           # spell-checking backend for :checkers spell
  ]
  ++ lib.optionals isDarwin [
    coreutils-prefixed # gls for terminal-launched Emacs / doom doctor

    # Expose the Doom build at system level so the mkalias activation script
    # (darwin/default.nix) bridges its Emacs.app into /Applications for
    # Spotlight/Dock. Same derivation home-manager installs — no duplication.
    config.home-manager.users.${vars.user}.programs.doom-emacs.finalEmacsPackage
  ];
}
