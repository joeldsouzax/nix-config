# Baseline

2026-10-21: existing edits affect README.md, darwin/homebrew.nix and modules/home/default.nix; modules/home/orca.nix is untracked. Preserve all four.

Codex 0.160.0; Claude Code 2.1.218; Graphify 0.9.32. Root nixpkgs input last changed 2026-06-26; multiple inputs last refreshed in July. Stable inputs target 25.05. CI uses checkout v4 and install-nix-action v30. Finder metadata exists at the root, modules/ and modules/editors/; the last is tracked.

Environment: aarch64-darwin; Determinate Nix 3.16.3 / Nix 2.33.3; 11 GB free. Inspection: git status --short, registry release queries, flake.lock inventory, relevant Nix sources and CI workflow. Rust checks and runtime benchmarks do not apply to this configuration-only refresh.

## 2026-10-30 CLI update

Clean Git working tree at start. macOS aarch64-darwin with 60 GiB free. Existing
Darwin native packages: Codex 0.163.0 and Claude Code 2.1.306. Desktop Nixpkgs
selects Codex 0.163.0 and Claude 2.1.303; headless Nixpkgs has Codex 0.163.0 and
Claude 2.1.308, but the headless system does not install Claude. Both Linux
profiles own duplicate Codex selections. No source/API behavior changes needed.
Latest npm package tags verified 2026-10-30: @openai/codex 0.166.0 and
@anthropic-ai/claude-code 2.1.314; corresponding native packages exist.

## 2026-10-30 storage cleanup

Host disk initially 71 GiB free of 461 GiB. UTM Homebrew registration exists
(4.7.5) and Nix still declares it, but /Applications/UTM.app is absent and Caskroom
contains only 12 KiB of receipt metadata. No UTM process seen. Library/Developer
36 GiB: DerivedData 16 GiB, DeviceSupport 5.6 GiB, CoreSimulator devices 13 GiB.
Library/Caches 7.3 GiB including CocoaPods 2 GiB and Homebrew 1.6 GiB. ~/.cache
7 GiB, Cargo downloads 4.8 GiB, Colima 12 GiB, project trees 41 GiB. Colima runs
five unhealthy local Labcast containers and has seven named volumes; Docker
image-list metadata reports input/output errors. Keep that data pending user
choice. Libvirt has no qemu:///session domains, but Trive networking declares
Homebrew nginx/dnsmasq and their root processes are running. Keep them.
Raw inventories: /tmp/storage-sizes.txt, /tmp/storage-details.txt,
/tmp/storage-vm-references.txt; package cleanup previews and GC preview in
/tmp/storage-*-preview.log. Existing agent-update working tree preserved.
