{ pkgs, vars, ... }:

let colors = import ../theming/colors.nix;
in {
  environment = { systemPackages = with pkgs; [ ghostty ]; };
  home-manager.users.${vars.user} = {
    programs = {
      ghostty = {
        enable = true;
        enableZshIntegration = true;
        settings = { font-size = 16; };
      };
    };
  };
}
