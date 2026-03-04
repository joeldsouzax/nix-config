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
        ignores = [
          "*.swp"
          ".gconf/"
          ".direnv/"
        ];
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
          credential.helper = "oauth";

          # Trive work account — repos under ~/Code/trive.ai/
          "includeIf \"gitdir:~/Code/trive.ai/\"" = {
            path = "~/.config/git/trive.inc";
          };
        };
        signing.key = "2CE4286073195A43";
        lfs = {
          enable = true;
        };

      };
    };
  };
}
