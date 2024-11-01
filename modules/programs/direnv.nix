# Git
#

{ vars, ... }:

{
  home-manager.users.${vars.user} = {
    programs = {
      enable = true;
      loadInNixShell = true;
      nix-direnv.enable = true;
      enableZshIntegration = true;
    };
  };
}
