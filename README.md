# nix-config

A single [Nix flake](https://nixos.wiki/wiki/Flakes) that declaratively manages
**two machines** from one repo:

| System | Attr | Platform | Highlights |
| --- | --- | --- | --- |
| **NixOS desktop** | `nixosConfigurations.main` | `x86_64-linux` | NVIDIA GPU, Hyprland (Wayland), foot terminal, declarative Doom Emacs |
| **macOS laptop** | `darwinConfigurations.joel` | `aarch64-darwin` | [nix-darwin](https://github.com/nix-darwin/nix-darwin), Aerospace WM, Homebrew for native apps, Ghostty |

Shared user-level config (shell, git, SSH, terminal theme, AI tooling) lives in
`modules/home/` and is consumed by **both** systems through home-manager.

---

## Quick start

```bash
# NixOS (the desktop)
sudo nixos-rebuild switch --flake .#main          # alias: rebuild

# macOS (the laptop)
sudo darwin-rebuild switch --flake ~/.setup#joel  # alias: nixswitch

# Update all flake inputs, then rebuild
nix flake update

# Validate without building
nix eval .#nixosConfigurations.main.config.system.build.toplevel --raw
nix eval .#darwinConfigurations.joel.config.system.build.toplevel --raw

# Parse-check a single file
nix-instantiate --parse path/to/file.nix
```

> The shell exposes `rebuild` (Linux) / `nixswitch` (macOS) aliases in **both**
> Nushell and ZSH. Nushell is the primary interactive shell.

---

## Repository layout

```
flake.nix              # inputs, vars, and both system outputs + `checks`
├─ hosts/              # NixOS-specific system config
│  ├─ default.nix      #   builds nixosConfigurations.main; sets `host` (hostname, monitors)
│  ├─ configuration.nix#   imports every module; users, nix settings, networking, secrets
│  └─ main/            #   hardware-configuration.nix + host tunables
├─ darwin/             # macOS-specific config
│  ├─ default.nix      #   entry point; imports shared modules/home
│  ├─ homebrew.nix     #   casks/brews for native macOS apps (incl. Ghostty)
│  ├─ networking.nix   #   DNS/proxy
│  └─ linux-builder.nix#   remote Linux builders (local aarch64 VM + the desktop over SSH)
├─ modules/
│  ├─ home/            # SHARED home-manager modules (shell, git, ssh, direnv,
│  │                   #   foot [Linux], ghostty [macOS], ai-agents)
│  ├─ desktops/        # NixOS WMs — hyprland (active), sway/river/bspwm/gnome (inert)
│  ├─ services/        # NixOS services — performance tuning, sxhkd, picom, polybar…
│  ├─ editors/         # Doom Emacs (declarative) + plain emacs
│  ├─ programs/        # NixOS app bundles (rofi, waybar, wofi, eww, obs…)
│  ├─ shell/           # extra shell bits
│  └─ theming/         # Catppuccin Mocha palette (colors.nix) + theming
├─ pkgs/               # custom derivations (e.g. claude-code.nix — macOS)
├─ secrets/            # SOPS-encrypted secrets (age); see .sops.yaml
├─ tests/              # nixosTest integration tests (checks.*.integration)
└─ docs/               # design notes & plans
```

---

## How it fits together

### Global `vars` + `host`
`flake.nix` defines `vars` (`user`, `location`, `terminal`, `editor`) passed to
every module via `specialArgs`. NixOS additionally gets a `host` attrset
(`hostname`, `mainMonitor`, `secondMonitor`) from `hosts/default.nix`. Modules
reference `vars.terminal`, `host.mainMonitor`, etc. — so e.g. changing the
terminal in one place updates every WM keybind.

### Cross-platform pattern
Shared modules guard platform-specific behaviour with
`pkgs.stdenv.isDarwin` / `isLinux` and `lib.optionalAttrs`. Canonical examples:

- **Terminal** — `modules/home/foot.nix` (Linux, `mkIf isLinux`) vs
  `modules/home/ghostty.nix` (macOS, `mkIf isDarwin`). `vars.terminal = "foot"`
  drives Linux WM keybinds; macOS keeps Ghostty via Homebrew.
- **Shell** — `modules/home/shell.nix` dispatches the `rebuild`/`nixswitch`
  alias to the right command per platform.

### Desktop (NixOS)
Hyprland on Wayland with NVIDIA. A single **3840×2160@60** monitor
(`hosts/default.nix → mainMonitor = "DP-3"`). `foot` is the terminal (Wayland-
native, low-latency on NVIDIA). Catppuccin Mocha throughout
(`modules/theming/colors.nix`).

### Editor — declarative Doom Emacs
`modules/editors/doom-emacs/` uses
[nix-doom-emacs-unstraightened](https://github.com/marienz/nix-doom-emacs-unstraightened):
Nix builds Doom **+** the `doom.d/` config into `emacs-pgtk` at rebuild time.
**No `doom sync`, ever** — `nixos-rebuild` yields a ready Emacs, and Doom is
pinned by the flake input. The daemon (`services.emacs`) is auto-wired to the
Doom build. Edit `doom.d/{init,packages,config}.el` and rebuild.

> **Toolchains come from projects, not globally.** Every project is a flake +
> [direnv](https://direnv.net/), so language servers (rust-analyzer, cargo,
> tsserver, gopls…) are provided by each project's devshell and picked up by
> lsp-mode. Only **Nix** tooling (`nil`, `alejandra`) is installed globally,
> since Nix files are edited outside project devshells.

### Performance (desktop)
`modules/services/performance.nix` + `hosts/configuration.nix`: zram (zstd),
tuned sysctls, earlyoom + systemd-oomd, per-device I/O schedulers, BBR, CPU
`performance` governor, `nvidiaPersistenced`, `max-jobs`/`cores` parallelism,
and **binary caches** (Hyprland + nix-community Cachix) so Hyprland isn't
compiled from source.

### Secrets
[sops-nix](https://github.com/Mic92/sops-nix) with age encryption. Secrets in
`secrets/secrets.yaml`, rules in `.sops.yaml`, wired in `hosts/configuration.nix`
(NixOS only). Access at runtime via `config.sops.secrets.<name>.path`. Shell/
home modules use `lib.attrByPath` to no-op when SOPS is absent (macOS).

### Remote Linux builds from macOS
`darwin/linux-builder.nix` wires two builders: a local `aarch64-linux` VM
(offline fallback) and the `x86_64-linux` **desktop over SSH** (`nixos.local`,
KVM, preferred). This lets the Mac build/eval Linux derivations and the
`checks.*.integration` nixosTests:

```bash
nix build .#checks.x86_64-linux.integration -L   # on the desktop (fast)
nix build .#checks.aarch64-linux.integration -L  # local VM (slow, TCG)
```

> **Known limitation:** on some macOS/QEMU versions the local aarch64 VM crashes
> on boot (Hypervisor.framework SME assertion), and the declarative Doom Emacs
> build needs IFD — so the full NixOS closure realistically builds **on the
> desktop**. `nix eval` still validates the config from either machine.

---

## Conventions

- Each module directory has a `default.nix` listing its imports.
- Home-manager is nested under `home-manager.users.${vars.user}` with
  `useGlobalPkgs = true`.
- Nixpkgs **unstable** is primary; `nixpkgs-stable` (25.05) is available as
  `stable` in `specialArgs`.
- Formatter: `nixfmt` (no enforced pre-commit hook).
- Add shell aliases/functions to **both** Nushell and ZSH.

## CI

`.github/workflows/check.yml` runs on push/PR to `main`: flake evaluation for
both NixOS and Darwin, plus syntax validation of all `.nix` files.
