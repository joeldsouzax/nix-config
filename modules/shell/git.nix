#  Git
#

{
  programs = {
    git = {
      enable = true;
      ignores = [ "*.swp" ];
      delta.enable = true;
      userName = "Joel DSouza";
      userEmail = "joeldsouzax@gmail.com";
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
}
