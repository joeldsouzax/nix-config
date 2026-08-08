# Shared Home-Manager Configuration
#
# Cross-platform modules imported by BOTH NixOS and Darwin.
# Each file sets home-manager.users.${vars.user}.* options.
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ configuration.nix ─── imports this ───┐
#   ├─ ./darwin                                   │
#   │   └─ default.nix ──── imports this ────┐    │
#   └─ ./modules                             │    │
#       └─ ./home                            │    │
#           ├─ default.nix *  <──────────────┴────┘
#           └─ ...

[
  ./shell.nix
  ./programs.nix
  ./agent-tools.nix
  ./local-llm.nix # llama.cpp + Qwen3-Coder-Rust for omp autoresearch (rust-llm)
  ./git.nix
  ./direnv.nix
  ./foot.nix # Linux/Wayland terminal (primary on the Hyprland desktop)
  ./ghostty.nix # macOS terminal (Darwin-guarded)
  ./ssh.nix
]
