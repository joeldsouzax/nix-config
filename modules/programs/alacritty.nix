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
