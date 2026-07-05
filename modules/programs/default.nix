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
  # ./kitty.nix
  ./obs.nix
  ./rofi.nix
  ./waybar.nix
  ./wofi.nix
  ./git.nix
  # ./direnv.nix  # moved to modules/home/direnv.nix (shared)
  # ./ghostty.nix  # removed — terminal is foot (Linux) via home-manager; see modules/home/foot.nix
  # ./games.nix
]
