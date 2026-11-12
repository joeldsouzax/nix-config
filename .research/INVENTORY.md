# Repository inventory

flake.nix and flake.lock own input revisions for both hosts. pkgs/ owns native macOS Codex/Claude packaging and Graphify's Darwin grammar fix. pkgs/rtw89-morrownr.nix is unreferenced; active WiFi uses nixpkgs rtl8852au. darwin/homebrew.nix requests update/upgrade on activation. .github/workflows/check.yml owns CI actions, both host evaluations, Linux integration tests and kernel builds. .gitignore owns Finder metadata exclusions.

Reuse Trive's existing nix flake update / nix flake check workflow; introduce no task runner or new setup. Preserve package features and platform support. Linux execution requires an available Linux builder; a Mac evaluation alone cannot prove Linux runtime behavior.

## 2026-10-30 coding agents

pkgs/codex.nix now owns one release and per-platform artifact/hash/vendor triples
for aarch64-darwin and x86_64-linux. Linux's bundled voice host is glibc-linked;
autoPatchelfHook fixes the loader and bundled library paths. Main Codex, rg,
code-mode host and bubblewrap are static PIE. pkgs/claude-code.nix owns one
release: existing Mac native wrapper remains, Linux uses the locked Nixpkgs
manifest override and its existing runtime dependencies/version check. Both
prebuilt local derivations use stdenvNoCC. hosts/default.nix owns Linux agent
installation once, included by both profiles. Mac retains its existing imports.
No new derivation framework, flake input, permanent command or test suite.
