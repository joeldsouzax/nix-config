#
#  Terminal Emulator
#

{ vars, ... }:

{
  home-manager.users.${vars.user} = {
    programs = {
      startship.enable = true;
      startship.enableZshIntegration = true;
      bat.enable = true;
    bat.config.theme = "TwoDark";
    fzf.enable = true;
    fzf.enableZshIntegration = true;
    eza.enable = true;
    dircolors = {
      enabnle = true;
      enableZshIntegration = true;
    };
      alacritty = {
        enable = true;
        settings = {
          font = {
            normal.family = "FiraCode Nerd Font";
            bold = { style = "Bold"; };
            size = 11;
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
