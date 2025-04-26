# Terminal Emulator
#

{ pkgs, vars, ... }:

{
  environment = { systemPackages = with pkgs; [ chawan ]; };
  home-manager.users.${vars.user} = {
    programs = {
      bat.enable = true;
      bat.config.theme = "TwoDark";
      fzf.enable = true;
      fzf.enableZshIntegration = true;

      eza = {
        enable = true;
        enableZshIntegration = true;
        colors = "always";
        git = true;
        icons = "always";
      };
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
      chawan = {
        enable = true;
        settings = {
          pager."C-k" = "() => pager.load('https://duckduckgo.com/?=')";
        };
      };
      gallery-dl = {
        enable = true;
        settings = { extractor.base-directory = "~/Downloads"; };
      };
    };
  };
}
