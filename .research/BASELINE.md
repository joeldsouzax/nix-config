# Baseline

2026-10-21: existing edits affect README.md, darwin/homebrew.nix and modules/home/default.nix; modules/home/orca.nix is untracked. Preserve all four.

Codex 0.160.0; Claude Code 2.1.218; Graphify 0.9.32. Root nixpkgs input last changed 2026-06-26; multiple inputs last refreshed in July. Stable inputs target 25.05. CI uses checkout v4 and install-nix-action v30. Finder metadata exists at the root, modules/ and modules/editors/; the last is tracked.

Environment: aarch64-darwin; Determinate Nix 3.16.3 / Nix 2.33.3; 11 GB free. Inspection: git status --short, registry release queries, flake.lock inventory, relevant Nix sources and CI workflow. Rust checks and runtime benchmarks do not apply to this configuration-only refresh.
