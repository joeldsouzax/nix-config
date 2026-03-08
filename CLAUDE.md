# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Apply Commands

**macOS (Darwin):**
```bash
sudo darwin-rebuild switch --flake ~/.setup#joel   # or alias: nixswitch
```

**NixOS:**
```bash
sudo nixos-rebuild switch --flake .#main   # or alias: rebuild
```

**Update flake inputs:**
```bash
nix flake update
```

**Validate syntax of a single file:**
```bash
nix-instantiate --parse path/to/file.nix
```

**Evaluate configurations without building:**
```bash
nix eval .#nixosConfigurations.main.config.system.build.toplevel --raw
nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw
```

**CI runs on push/PR to main** — checks flake evaluation for both NixOS and Darwin, plus syntax validation of all .nix files.

## Architecture

This is a unified Nix flake managing two systems from a single `flake.nix`:

- **NixOS** (`nixosConfigurations.main`) — x86_64-linux desktop with NVIDIA GPU, Hyprland (Wayland)
- **macOS** (`darwinConfigurations.joel`) — aarch64-darwin laptop with Aerospace (tiling WM), Homebrew for native apps

### Key Directories

- `hosts/` — NixOS-specific system config. `hosts/default.nix` is the entry point; `hosts/configuration.nix` imports all modules.
- `darwin/` — macOS-specific config. `darwin/default.nix` is the entry point; `homebrew.nix` manages casks/brews; `networking.nix` handles DNS/proxy.
- `modules/home/` — **Shared home-manager modules** used by both platforms (shell, git, SSH, ghostty, programs, direnv). This is the cross-platform layer.
- `modules/desktops/`, `modules/services/`, `modules/editors/`, `modules/programs/`, `modules/theming/` — NixOS-only modules imported by `hosts/configuration.nix`.
- `pkgs/` — Custom package derivations (e.g., `claude-code.nix`).
- `secrets/` — SOPS-encrypted secrets (age encryption). Configured in `.sops.yaml`.

### Configuration Pattern

Global variables (`user`, `location`, `terminal`, `editor`) are defined in `flake.nix` under `vars` and passed to all modules via `specialArgs`. Modules reference them as `vars.user`, `vars.terminal`, etc.

### Cross-Platform Handling

Modules use `pkgs.stdenv.isDarwin` / `pkgs.stdenv.isLinux` guards and `lib.optionalString` for platform-specific behavior. See `modules/home/shell.nix` for the canonical pattern — the `nix switch` alias/command dispatches to the right rebuild command per platform.

### Secrets

SOPS-nix with age encryption. Secrets are in `secrets/secrets.yaml`, configured in `hosts/configuration.nix` (NixOS only). Access at runtime via `config.sops.secrets.<name>.path`. The shell module uses `lib.attrByPath` to safely check for SOPS availability (absent on Darwin).

## Nix Conventions

- Each module directory has a `default.nix` that lists its imports.
- Home-manager config is nested under `home-manager.users.${vars.user}` with `useGlobalPkgs = true`.
- Nixpkgs unstable is the primary channel; `nixpkgs-stable` (25.05) is available as `stable` in specialArgs.
- Formatter: `nixfmt` is available but no enforced pre-commit hook.
