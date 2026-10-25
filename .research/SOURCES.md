# Research sources

Accessed 2026-10-21:

- https://learn.chatgpt.com/docs/codex/cli — official update guidance; preserve Nix package ownership.
- https://registry.npmjs.org/@openai/codex/latest — stable 0.163.0, Apache-2.0; verify native arm64 artifact and hash.
- https://registry.npmjs.org/@anthropic-ai/claude-code/latest — stable 2.1.306, unfree; verify existing native packaging still fits.
- https://github.com/Graphify-Labs/graphify/releases/tag/v0.9.93 and its pyproject.toml — latest release, Apache-2.0; Python >=3.10, tree-sitter >=0.25,<0.26. Existing supported Nix Python builder remains appropriate.
- https://raw.githubusercontent.com/NixOS/nixpkgs/nixos-unstable/pkgs/by-name/gr/graphify/package.nix — nixpkgs 0.9.91 remains behind current release; preserve existing integrations and Darwin grammar fix.
- https://github.com/actions/checkout/releases/tag/v7.0.1 — Node 24, current GitHub-hosted runners supported.
- https://github.com/cachix/install-nix-action/releases/tag/v31.11.2 — composite action; existing configured inputs supported.
- https://api.github.com/repos/NixOS/nixpkgs/branches/nixos-26.05 — current stable branch exists; pair with Home Manager release-26.05.
- https://api.github.com/repos/morrownr/rtw89/commits/main — latest 3cdbb6b81e00b72cf27bbdd4d4f1b96f9c15be27, 2026-10-13. Inactive derivation; do not change active NIC ownership.
- https://raw.githubusercontent.com/NixOS/nixpkgs/02c087f3fe673c9e317f206a627cb6b910336dbe/pkgs/development/libraries/aspell/dictionaries.nix — en-computers and en-science were removed 2026-09-28; retained ds.en avoids compromised/unavailable sources.
- Locked nixpkgs python-packages-base.nix: makePythonPath includes requiredPythonModules transitively. Use the supported wrapper argument instead of patching upstream Python code.
- Locked nixpkgs Codex is also 0.163.0, but builds Rust/V8 from source. Retain the existing upstream native-binary packaging and its bundled helpers to preserve behavior and limit build cost.

Accessed 2026-10-25 for the desktop runner:

- https://learn.chatgpt.com/docs/cli — the CLI supports Linux; run `codex` in a
  project and complete first-run sign-in. Nix remains the package owner here.
- Locked `nixpkgs-runner` at `3ec636362e1816bc2f0888fa0fa2c69f1bc9e504`,
  `pkgs/by-name/co/codex/package.nix`: Codex 0.163.0, Apache-2.0, Unix platforms,
  maintained source package with code-mode/voice helpers, Linux bubblewrap,
  shell completions and a version installation check. Reuse this Linux package;
  the existing custom package is specifically for the Mac.
- cache.nixos.org has the signed x86_64-linux output
  `/nix/store/85jfacgc74z186chfvivryyb61nbxa63-codex-0.163.0`:
  181,795,535 bytes compressed, 612,490,376 bytes unpacked for this output alone.
  This avoids a local Rust/V8 build; it does not establish runtime correctness.
- The same locked nixpkgs input's
  `nixos/modules/services/networking/ssh/sshd.nix` defines
  `users.users.<name>.openssh.authorizedKeys.keyFiles`. It reads public keys at
  build time into `/etc/ssh/authorized_keys.d/<name>` and preserves the user's
  home-directory authorized keys by default. Both evaluated profiles confirm
  this behavior for Joel.

Accessed 2026-10-25 for desktop compatibility:

- https://raw.githubusercontent.com/NixOS/nixpkgs/02c087f3fe673c9e317f206a627cb6b910336dbe/pkgs/top-level/aliases.nix
  records `grip` removal on 2026-07-30 because it used GTK2. The locked package
  fails evaluation; removing the obsolete application entry fixes that failure.
- The same revision's `pkgs/stdenv/generic/default.nix` forwards the deprecated
  `stdenv.isDarwin` and `stdenv.isLinux` aliases to `stdenv.hostPlatform` fields
  while emitting warnings. Use the owning platform fields directly; this is a
  spelling update with the same platform selection.
- The actual package checks use locked nixpkgs revisions `02c087f` (desktop and
  Mac) and `3ec6363` (runner). No dependency pin changed during this repair.
  The Mac's full toplevel derivation stays identical after the platform update.

Accessed 2026-10-25 for RTL8852AU:

- Owner photo `/Users/joel/Downloads/IMG_4539.HEIC`: actual Linux 6.12.113 build
  rejects the callback's two-parameter function pointer. The system build then
  fails through its kernel-module dependency. The photo also shows a Codex
  invocation after the failed regular desktop build.
- https://github.com/gregkh/linux/commit/4dae80dd259b5c24f6c657f434afd5de1f791d12
  backports `net_device` into `set_monitor_channel`. The maintainer's GitHub API
  supplies the exact diff; raw published `include/net/cfg80211.h` files at
  v6.12.100 and v6.12.101 establish the release boundary. The v6.12.113,
  v6.12.114 and v6.13 headers confirm the supported callback signatures.
- https://raw.githubusercontent.com/NixOS/nixpkgs/master/pkgs/os-specific/linux/rtl8852au/default.nix
  and the locked package both retain source 865ab0fa91471d595c283d2f3db323f7f15455f5
  with nixpkgs' `fix-build-for-kernels-6.13-6.14.patch`. Nixpkgs' and the driver's
  current GitHub histories contain no newer fix for this backport.
- https://github.com/lwfinger/rtl8852au/pull/115 supplies the existing callback
  compatibility patch. Extend its version guard to 6.12.101; keep its existing
  implementation and the separate namespace/get-txpower guards.
- Both locked inputs supply Codex 0.163.0. The regular desktop's Linux output
  `/nix/store/03h8zqzsxqrvlr143r5h2vzzx8mhqp95-codex-0.163.0` is present in the
  signed NixOS binary cache. No custom Linux Codex builder is needed.
# Kernel module installation follow-up, 2026-10-25

- https://github.com/NixOS/nixpkgs/issues/575192: maintainer confirms that direct
  `.ko` copying bypasses signing/compression. Use `kernelModuleMakeFlags` and
  Kbuild `modules_install`; this applies to the locked RTL8852AU installer.
- https://github.com/NixOS/nixpkgs/pull/571181: deterministic module certificates
  landed on 2026-10-14. The aggregator requires certificates for external modules.
- Locked runner nixpkgs 3ec636362e1816bc2f0888fa0fa2c69f1bc9e504:
  `pkgs/os-specific/linux/zenpower/default.nix` demonstrates supported installation;
  `pkgs/top-level/linux-kernels.nix` owns stripping, depmod and signing flags.
  `pkgs/os-specific/linux/kmod/aggregator.nix` supplies the failing integration
  check. RTL8852AU's current upstream nixpkgs expression still copies the module
  directly, so a lock update does not supply this fix.
# Travel access and host limits, 2026-10-25

- Live desktop inspection: Intel i5-9400F (six physical cores), 15 GiB usable RAM,
  SSD root and Nix store, HDD project directory; performance governor already
  active. Wi-Fi profile autoconnects and has no per-user restriction. During the
  bounded Hyprland build an SSH/memory probe completes in 0.50 s, with 10 GiB
  available RAM and zero measured memory pressure. This is a responsiveness
  sample, not a throughput comparison. `/tmp/nix-travel-build-responsiveness.log`.
- https://tailscale.com/docs/reference/connection-types: private connectivity
  uses direct connections or relays; router forwarding/public addresses are not
  required for this setup.
- https://tailscale.com/docs/install/linux and
  https://tailscale.com/docs/how-to/run-unattended: Linux uses a system daemon,
  with account enrollment and device-key expiry handled separately.
- https://tailscale.com/docs/install/mac: official standalone macOS app and
  user approval for VPN setup. The established Darwin Homebrew owner now contains
  `tailscale-app`. `brew info --cask tailscale-app --json=v2` resolves version
  1.104.2 from `pkgs.tailscale.com`; the installer is fetched, not installed.
- Locked Nixpkgs `nixos/modules/services/networking/tailscale.nix` supplies the
  boot service, firewall port and declarative `extraSetFlags`. Its NetworkManager
  module supports `wifi.powersave = false`. No custom service is needed.
- The owner subsequently installed and signed into the Mac app; the CLI reports
  `Running`, online, with no peers before desktop enrollment. Installation remains
  owned by the Darwin configuration. The remote host's verified Ed25519 key has
  fingerprint `SHA256:a04A3OAMZkP9D8hGUQtEpwGgT7qlKMvecNNSWisDStg`; the Darwin
  module renders it for both `nixos.local` and `labcast-desktop`.

Hyprland recovery, 2026-10-25:

- Owner photo IMG_4540.HEIC: autogenerated `hyprland.lua`, default Kitty shortcut,
  no configured menu. The owner uses a Mac keyboard; Ctrl+Option+Fn+F2 reaches
  the text console. Desktop SSH is pending saved Wi-Fi reconnection.
- Locked Hyprland c7216a9807a2683ce243f6ed14ae01e7e884c426:
  `src/config/supplementary/jeremy/Jeremy.cpp` only discovers `.lua`;
  `src/config/ConfigManager.cpp` only constructs the Lua manager;
  `example/hyprland.lua` and Lua binding sources supply the actual API.
  `src/main.cpp` and `src/Compositor.cpp` implement `--verify-config` without
  starting the compositor and return a failing status on configuration errors.
- https://wiki.hypr.land/Configuring/Start/ documents the Lua configuration path
  and migration since 0.55. The locked source, not older compatibility comments,
  controls support in the version actually built.
- Locked Home Manager `modules/services/window-managers/hyprland/lib.nix`
  renders `settings.<name>` as `hl.<name>(...)`; `_args` and `mkLuaInline` are
  supported. `extraConfig` holds ordinary Lua for callbacks and loops.
- Locked NixOS `system/activation/top-level.nix`: `system.checks` requires
  successful build-time checks without retaining them in the system closure.

### H11 desktop startup sources (2026-10-25)

- https://aylur.github.io/gnim/gobject.html requires
  `experimentalDecorators: false` and `target: ES2020` (or earlier). The actual
  locked GNIM failure is decorator metadata undefined in `gnim/dist/dbus.ts`.
- https://wiki.hypr.land/hypr-ecosystem/user/hypridle/ documents the mandatory
  config and `general.lock_cmd`. No new idle listener or sleep action is needed.
- Locked Home Manager `modules/services/udiskie.nix` explicitly requires
  NixOS `services.udisks2.enable`; live D-Bus reports it is not activatable.
- The installed Catppuccin package lists `catppuccin-mocha-blue-standard`,
  `-hdpi` and `-xhdpi`; the configured title-case name does not exist.
- SwayNC's installed systemd unit and live journal establish the duplicate
  startup: the direct UWSM process owns the instance while D-Bus starts the
  packaged service, which repeatedly exits with "already running".
