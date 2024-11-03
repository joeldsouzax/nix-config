# Virtualisation Modules
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./<host>
#   │       └─ default.nix
#   └─ ./modules
#       └─ ./desktops
#           └─ ./virtualisation
#               ├─ default.nix *
#               └─ ...
#

[ ./podman.nix ./qemu.nix ./x11vnc.nix ]
