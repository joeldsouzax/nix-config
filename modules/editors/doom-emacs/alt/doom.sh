#!/bin/sh

DOOM="$HOME/.emacs.d"

if [ ! -d "$DOOM" ]; then
  git clone https://github.com/hlissner/doom-emacs.git $DOOM
  kitty -e $DOOM/bin/doom -y install & disown
else
  kitty -e $DOOM/bin/doom sync
fi

