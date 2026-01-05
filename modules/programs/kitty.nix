{ pkgs, vars, ... }:

let

  colors = import ../theming/colors.nix;
in {

  environment.systemPackages = with pkgs; [ ghostty nushell ];

  home-manager.users.${vars.user} = {
    programs = {
      # Optional: Basic Nushell config (if not managed elsewhere)
      # nushell.enable = true; 

      ghostty = {
        enable = true;
        enableZshIntegration = true; # Keep enabled for legacy compatibility

        settings = {
          # --- 1. The "Power Coder" Shell ---
          # Launches Nushell by default.
          # Why? 'ls', 'ps', 'sys' output structured tables you can query like SQL.
          command = "${pkgs.nushell}/bin/nu";

          # --- 2. Visuals (Hyprland Optimized) ---
          # Font: Use the one installed in your theming module
          font-family = "FiraCode Nerd Font Mono";
          font-size = 13; # 16 is huge. 13 is standard for 1080p/1440p coding.
          font-thicken = true; # Makes fonts clearer/bolder on Linux rendering

          # Theme: Matches your system
          theme = "catppuccin-mocha";

          # Clean UI: Remove borders (let Hyprland handle them)
          window-decoration = false;
          window-padding-x = 6;
          window-padding-y = 6;
          window-padding-balance = true;

          # Cursor
          cursor-style = "block";
          cursor-style-blink = false; # Solid block is less distracting
          shell-integration-features =
            "no-cursor,sudo,no-title"; # Hide title bar junk

          # --- 3. Performance & Interaction ---
          gtk-single-instance = true; # Saves RAM, faster startup
          mouse-scroll-multiplier = 2;
          copy-on-select = "clipboard"; # Auto-copy selection (God-tier feature)
          window-save-state = "always"; # Remember layout on restart

          # --- 4. Keybindings (Doom Emacs Style) ---
          # We use '>' for sequences (chord chains) to match Emacs muscle memory
          keybind = [
            # Tabs (Standard)
            "ctrl+t=new_tab"
            "ctrl+w=close_tab"
            "ctrl+shift+l=next_tab"
            "ctrl+shift+h=previous_tab"

            # Fast Tab Switching (Alt is often faster than Ctrl for numbers)
            "alt+1=goto_tab:1"
            "alt+2=goto_tab:2"
            "alt+3=goto_tab:3"
            "alt+4=goto_tab:4"
            "alt+5=goto_tab:5"
            "alt+6=goto_tab:6"
            "alt+7=goto_tab:7"
            "alt+8=goto_tab:8"
            "alt+9=goto_tab:9"

            # Splits -> Mimicking Emacs 'C-x' Chords
            # ctrl-x then 2 = Split Down
            "ctrl+x>2=new_split:down"
            # ctrl-x then 3 = Split Right
            "ctrl+x>3=new_split:right"
            # ctrl-x then o = Cycle Split (Other window)
            "ctrl+x>o=goto_split:next"
            # ctrl-x then k = Close Split (Kill buffer)
            "ctrl+x>k=close_surface"

            # Resize Splits quickly
            "ctrl+left=resize_split:left,20"
            "ctrl+right=resize_split:right,20"
            "ctrl+up=resize_split:up,20"
            "ctrl+down=resize_split:down,20"

            # Zoom
            "ctrl+equal=increase_font_size:1"
            "ctrl+minus=decrease_font_size:1"
            "ctrl+0=reset_font_size"

            # Utils
            "ctrl+shift+r=reload_config" # Reload config live
          ];
        };
      };
    };
  };
}
