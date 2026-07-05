# Apps
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ configuration.nix
#   └─ ./modules
#       └─ ./programs
#           ├─ default.nix *
#           └─ ...
#

[
  ./others.nix
  ./accounts.nix
  ./eww.nix
  ./flatpak.nix
  ./obs.nix
  ./waybar.nix
  ./wofi.nix
  ./git.nix
]
