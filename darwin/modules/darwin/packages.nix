{ pkgs, ... }:

with pkgs; [
  # General packages for development and system management
  bat
  coreutils
  nixfmt-classic
  shfmt
  shellcheck
  graphviz
  nodejs
  sqlite
  ispell

  ## emacs stuff
  emacsPackages.grip-mode
  emacsPackages.editorconfig
  emacsPackages.plantuml-mode
  multimarkdown

  #emacs mail deps
  mu
  isync
  msmtp

  # crone keyboard deps
  libusb
  dfu-programmer
  avrdude

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Text and terminal utilities
  ripgrep
  tree
  unzip
  cmake
  gnuplot

  #language servers and language settings
  yaml-language-server
  bash-language-server

  #raspberry-pi
]
