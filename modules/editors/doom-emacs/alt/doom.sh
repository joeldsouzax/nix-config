#!/bin/sh

DOOM="$HOME/.emacs.d"

if [ ! -d "$DOOM" ]; then
  git clone https://github.com/hlissner/doom-emacs.git $DOOM
  ghostty -e $DOOM/bin/doom -y install &
  disown
else
  ghostty -e $DOOM/bin/doom sync
fi
