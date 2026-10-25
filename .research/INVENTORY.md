# Repository inventory

flake.nix and flake.lock own input revisions for both hosts. pkgs/ owns native macOS Codex/Claude packaging and Graphify's Darwin grammar fix. pkgs/rtw89-morrownr.nix is unreferenced; active WiFi uses nixpkgs rtl8852au. darwin/homebrew.nix requests update/upgrade on activation. .github/workflows/check.yml owns CI actions, both host evaluations, Linux integration tests and kernel builds. .gitignore owns Finder metadata exclusions.

Reuse Trive's existing nix flake update / nix flake check workflow; introduce no task runner or new setup. Preserve package features and platform support. Linux execution requires an available Linux builder; a Mac evaluation alone cannot prove Linux runtime behavior.
