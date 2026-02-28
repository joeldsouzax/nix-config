# Services
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ configuration.nix
#   └─ ./modules
#       └─ ./services
#           └─ default.nix *
#               └─ ...
#

[
  ./avahi.nix
  # ./dunst.nix
  ./expressvpn.nix
  ./flameshot.nix
  ./picom.nix
  ./polybar.nix
  ./samba.nix
  ./swaync.nix
  ./sxhkd.nix
  ./udiskie.nix
  ./securities.nix
  ./emails.nix
  ./performance.nix
]
