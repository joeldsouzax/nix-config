# Dead ends

Graphify 0.9.93 initially built and answered queries, but graphify update . failed with No module named graphify. Its restart bypassed the Nix entry point's injected module paths. Retained fix: export the package and transitive dependencies through supported makeWrapperArgs/makePythonPath. Actual graph update then succeeded.

Initial flake check with Determinate lazy-trees=true failed with an invalid source-store path during Hyprland evaluation. Retrying with lazy-trees=false, without changing system settings. Direct desktop SSH fails to resolve nixos.local; do not claim Linux execution coverage without an available builder or CI.

A final flake check with both lazy-trees=false and eval-cache=false still reports an invalid path for the Linux Doom intermediate. These command-line changes did not establish a fix. Separate NixOS evaluation with builders disabled gives the concrete missing x86_64-linux execution error. Retain the actual failure rather than weakening the flake gate.
