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
