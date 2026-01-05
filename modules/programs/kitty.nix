# Terminal Emulator
#

{ pkgs, vars, ... }:

let colors = import ../theming/colors.nix;
in {
  environment = { systemPackages = with pkgs; [ kitty ]; };

  home-manager.users.${vars.user} = {
    programs = {
      kitty = {
        enable = true;
        themeFile = "Afterglow";
        keybindings = {
          "ctrl+1" = "goto_tab 1";
          "ctrl+2" = "goto_tab 2";
          "ctrl+3" = "goto_tab 3";
          "ctrl+4" = "goto_tab 4";
        };
        settings = {
          confirm_os_window_close = 0;
          enable_audio_bell = "no";
          resize_debounce_time = "0";
          background = "#${colors.scheme.default.hex.bg}";
          font_family = "FiraCode Nerd Font";
        };
      };
    };
  };
}
