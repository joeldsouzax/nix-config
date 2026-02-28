# Ghostty Terminal Configuration
# Shared between NixOS and Darwin via home-manager
# Uses Catppuccin Mocha theme from theming/colors.nix

{ lib, pkgs, vars, ... }:

let
  colors = import ../theming/colors.nix;
  c = colors.scheme.default.hex;
in
{
  home-manager.users.${vars.user}.programs.ghostty = {
    enable = true;
    enableZshIntegration = true;
    # Ghostty Nix package is Linux-only; macOS uses Homebrew cask (see darwin/homebrew.nix)
    package = if pkgs.stdenv.isDarwin then null else pkgs.ghostty;
    settings = {
      # Shell
      command = "${pkgs.nushell}/bin/nu";

      # Font
      font-family = "FiraCode Nerd Font Mono";
      font-size = 13;
      font-thicken = true;
      window-padding-balance = true;

      # Catppuccin Mocha Theme
      background = "#${c.bg}";
      foreground = "#${c.fg}";
      cursor-color = "#${c.highlight}";
      selection-background = "#${c.inactive}";
      selection-foreground = "#${c.fg}";
      palette = [
        "0=#${c.black}"
        "1=#${c.red}"
        "2=#${c.green}"
        "3=#${c.yellow}"
        "4=#${c.blue}"
        "5=#${c.purple}"
        "6=#${c.cyan}"
        "7=#${c.white}"
        "8=#${c.gray}"
        "9=#${c.red}"
        "10=#${c.green}"
        "11=#${c.yellow}"
        "12=#${c.blue}"
        "13=#${c.purple}"
        "14=#${c.cyan}"
        "15=#${c.white}"
      ];

      # Behavior
      copy-on-select = "clipboard";
      mouse-scroll-multiplier = 2;
      cursor-style = "block";
      cursor-style-blink = false;

      # Keybinds
      keybind = [
        "ctrl+t=new_tab"
        "ctrl+w=close_tab"
        "alt+1=goto_tab:1"
        "alt+2=goto_tab:2"
        "alt+3=goto_tab:3"
        "ctrl+x>2=new_split:down"
        "ctrl+x>3=new_split:right"
        "ctrl+x>o=goto_split:next"
        "ctrl+x>k=close_surface"
        "ctrl+equal=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+0=reset_font_size"
        "ctrl+shift+r=reload_config"
      ];
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      # Linux: no title bar (Hyprland manages it)
      window-decoration = false;
      gtk-single-instance = true;
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # macOS: native title bar with tabs
      macos-titlebar-style = "tabs";
    };
  };
}
