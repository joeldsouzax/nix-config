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
  ./expressvpn.nix
  ./flameshot.nix
  ./samba.nix
  ./swaync.nix
  ./udiskie.nix
  ./securities.nix
  ./performance.nix
]
