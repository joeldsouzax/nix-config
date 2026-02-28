#
#  Shell
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ configuration.nix
#   └─ ./modules
#       └─ ./shell
#           ├─ default.nix *
#           └─ ...
#

[
  ./git.nix
  ./zsh.nix
  # ./direnv.nix  # moved to modules/home/direnv.nix (shared)
]
