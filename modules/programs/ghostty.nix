{ pkgs, vars, ... }:

let colors = import ../theming/colors.nix;
in {
  environment = { systemPackages = with pkgs; [ ghostty ]; };
  home-manager.users.${vars.user} = {
    programs = {
      ghostty = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          font-size = 16;
          cursor-style = "block";
          mouse-scroll-multiplier = 2;
          copy-on-select = "clipboard";
          shell-integration-features = "no-cursor,sudo,no-title";
          window-padding-balance = true;
          window-save-state = "always";
          keybind = [
            "ctrl+t=new_tab"
            "ctrl+w=close_tab"
            "cmd+s=reload_config"
            "ctrl+1=goto_tab:1"
            "ctrl+2=goto_tab:2"
            "ctrl+3=goto_tab:3"
            "ctrl+4=goto_tab:4"
            "ctrl+5=goto_tab:5"
            "ctrl+6=goto_tab:6"
            "ctrl+7=goto_tab:7"
            "ctrl+8=goto_tab:8"
            "ctrl>x>2=new_split:down"
            "ctrl>x>3=new_split:right"
            # "ctrl+x+right=goto_split:right"
            # "ctrl+x+up=goto_split:up"
            # "ctrl+x+down=goto_split:down"
            # "ctrl+x+left=goto_split:left"
          ];
        };
      };
    };
  };
}
