# Terminal Emulator
#

{ vars, ... }:

{
  home-manager.users.${vars.user} = {
    programs = {
      git = {
        enable = true;
        ignores = [ "*.swp" ];
        delta.enable = true;
        userName = "Joel DSouza";
        userEmail = "joeldsouzax@gmail.com";
        signing.key = "A3C444A7";
        lfs = { enable = true; };
        extraConfig = {
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
      };
    };
  };
}
