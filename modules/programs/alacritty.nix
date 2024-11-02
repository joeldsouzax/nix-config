# Terminal Emulator
#

{ vars, ... }:

{
  home-manager.users.${vars.user} = {
    programs = {
      bat.enable = true;
      bat.config.theme = "TwoDark";
      fzf.enable = true;
      fzf.enableZshIntegration = true;
      eza.enable = true;
      dircolors = {
        enable = true;
        enableZshIntegration = true;
      };
      starship.enable = true;
      starship.enableZshIntegration = true;
      autojump = {
        enable = true;
        enableZshIntegration = true;
      };
      hstr = {
        enable = true;
        enableZshIntegration = true;
      };
      bacon = {
        enable = true;
        settings = {
          jobs = {
            default = {
              command = [ "cargo" "build" "--all-features" "--color" "always" ];
              need_stdout = true;
            };
          };
        };
      };
      alacritty = {
        enable = true;
        settings = {
          font = {
            normal.family = "FiraCode Nerd Font";
            bold = { style = "Bold"; };
            size = 16;
          };
          offset = {
            x = -1;
            y = 0;
          };
        };
      };
    };
  };
}
