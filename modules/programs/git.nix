# Git
#

{ vars, ... }:

{
  home-manager.users.${vars.user} = {
    programs = {
      delta = {
        enable = true;
        enableGitIntegration = true;
      };
      git = {
        enable = true;
        ignores = [ "*.swp" ];
        settings = {
          user.name = "Joel DSouza";
          user.email = "joeldsouzax@gmail.com";
          init.defaultBranch = "main";
          core = {
            editor = "emacs";
            autocrlf = "input";
          };
          commit.gpgsign = true;
          pull.rebase = true;
          rebase.autoStash = true;
          extraConfig = { credential.helper = "oauth"; };
        };
        signing.key = "2CE4286073195A43";
        lfs = { enable = true; };

      };
    };
  };
}
