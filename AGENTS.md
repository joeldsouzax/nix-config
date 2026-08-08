# Repository agent guide

This repository is a unified Nix flake for two systems:

- `nixosConfigurations.main`: x86_64-linux desktop with NVIDIA and Hyprland.
- `darwinConfigurations.joel`: aarch64-darwin laptop with Aerospace and Homebrew.

## Commands

```bash
sudo darwin-rebuild switch --flake ~/.setup#joel  # macOS; alias: nixswitch
sudo nixos-rebuild switch --flake .#main          # NixOS; alias: rebuild
nix flake update
nix-instantiate --parse path/to/file.nix
nix eval .#nixosConfigurations.main.config.system.build.toplevel --raw
nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw
```

CI evaluates both systems and parses all Nix files. Run the narrowest relevant checks locally before handing off a change. Do not run a rebuild that needs `sudo` unless the user asks to apply the configuration.

## Architecture

- `hosts/`: NixOS entry point and system modules.
- `darwin/`: nix-darwin entry point, networking, and Homebrew.
- `modules/home/`: shared Home Manager modules for both platforms.
- `modules/{desktops,services,editors,programs,theming}/`: primarily NixOS modules.
- `pkgs/`: custom derivations, including pinned agent CLIs.
- `secrets/`: SOPS-encrypted material; never print decrypted secret values.

Global values such as `user`, `location`, `terminal`, and `editor` are defined in `flake.nix` and passed through `specialArgs` as `vars`. Keep cross-platform configuration in shared Home Manager modules and use `pkgs.stdenv.isDarwin` or `pkgs.stdenv.isLinux` guards.

## Nix conventions

- Directory `default.nix` files own their import lists.
- Shared user configuration is nested under `home-manager.users.${vars.user}`.
- Use unstable nixpkgs by default; `stable` is available through `specialArgs` where needed.
- Format touched Nix files with `nixfmt` when practical.
- Preserve unrelated working-tree changes; this repository is often edited by multiple agent harnesses.

## Codebase navigation

When `graphify-out/graph.json` exists, start broad codebase questions with `graphify query`, `graphify explain`, or `graphify path`. Use `graphify-out/wiki/index.md` for broad navigation and read `GRAPH_REPORT.md` only when scoped queries are insufficient. After code changes, run `graphify update .`; `graphify-out/` is generated and ignored.

Prefer `rg`/`rg --files` for search, `fd` for interactive file discovery, `ast-grep` (`sg`) for structural search, and `difftastic` for semantic comparisons.

## Agent interoperability

- Codex workflows live under `.codex/skills/`.
- Claude Code reads this guide through `CLAUDE.md`.
- OMP/Kimi remains available for independent review and long-running autoresearch; use the repo-local Codex skills when those workflows are requested.
