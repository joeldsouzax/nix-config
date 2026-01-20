{ pkgs, vars, ... }:
let
  colors = import ../theming/colors.nix;
  c = colors.scheme.default.hex;
in
{
  environment.systemPackages = with pkgs; [ ghostty ];

  home-manager.users.${vars.user} = {
    programs = {
      ghostty = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          # Shell
          command = "${pkgs.nushell}/bin/nu";

          # Visuals
          font-family = "FiraCode Nerd Font Mono";
          font-size = 13;
          font-thicken = true;
          window-decoration = false;
          window-padding-balance = true;

          # --- DYNAMIC THEME (Syncs with colors.nix) ---
          background = "#${c.bg}";
          foreground = "#${c.fg}";
          cursor-color = "#${c.highlight}";
          selection-background = "#${c.inactive}";
          selection-foreground = "#${c.fg}";

          # Map your 8 base colors to the 16-color palette
          palette = [
            "0=#${c.black}"
            "1=#${c.red}"
            "2=#${c.green}"
            "3=#${c.yellow}"
            "4=#${c.blue}"
            "5=#${c.purple}"
            "6=#${c.cyan}"
            "7=#${c.white}"
            "8=#${c.gray}" # Bright Black
            "9=#${c.red}" # Bright Red (Reuse base if specific brights aren't defined)
            "10=#${c.green}"
            "11=#${c.yellow}"
            "12=#${c.blue}"
            "13=#${c.purple}"
            "14=#${c.cyan}"
            "15=#${c.white}"
          ];

          # Behavior
          gtk-single-instance = true;
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
        };
      };
    };
  };
}
