# foot Terminal Configuration (Linux / Wayland only)
#
# foot is a Wayland-native, minimal-dependency terminal — chosen as the primary
# terminal on the Hyprland desktop for low latency on NVIDIA + Wayland, where
# Ghostty's GL renderer was sluggish. macOS keeps Ghostty (see ghostty.nix,
# guarded to Darwin). Palette: Catppuccin Mocha from theming/colors.nix.

{ lib, pkgs, vars, ... }:

let
  colors = import ../theming/colors.nix;
  c = colors.scheme.default.hex;
in
{
  # Linux-only: pkgs.foot does not exist on Darwin.
  home-manager.users.${vars.user} = lib.mkIf pkgs.stdenv.isLinux {
    programs.foot = {
      enable = true;
      package = pkgs.foot;

      # foot server: `footclient` spawns new windows against a resident server
      # process, so opening a terminal is near-instant (no cold start).
      server.enable = true;

      settings = {
        main = {
          # xterm-256color keeps SSH into hosts without foot's terminfo happy.
          term = "xterm-256color";
          font = "FiraCode Nerd Font Mono:size=13";
          dpi-aware = "no"; # scale 1 on the 4K panel — size in points, predictable
          pad = "8x8";
          # Nushell as the interactive shell (matches the previous Ghostty setup).
          shell = "${pkgs.nushell}/bin/nu";
        };

        cursor = {
          style = "block";
          blink = "no";
          # "<text-under-cursor> <cursor-block>"
          color = "${c.bg} ${c.highlight}";
        };

        mouse = {
          hide-when-typing = "yes";
        };

        scrollback = {
          lines = 10000;
        };

        # Catppuccin Mocha
        colors = {
          background = c.bg;
          foreground = c.fg;

          selection-foreground = c.fg;
          selection-background = c.inactive;

          regular0 = c.black;
          regular1 = c.red;
          regular2 = c.green;
          regular3 = c.yellow;
          regular4 = c.blue;
          regular5 = c.purple;
          regular6 = c.cyan;
          regular7 = c.white;

          bright0 = c.gray;
          bright1 = c.red;
          bright2 = c.green;
          bright3 = c.yellow;
          bright4 = c.blue;
          bright5 = c.purple;
          bright6 = c.cyan;
          bright7 = c.white;
        };

        key-bindings = {
          font-increase = "Control+equal";
          font-decrease = "Control+minus";
          font-reset = "Control+0";
        };
      };
    };
  };
}
