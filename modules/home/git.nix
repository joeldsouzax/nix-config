# Git Configuration
# Shared between NixOS and Darwin via home-manager

{ vars, ... }:

{
  home-manager.users.${vars.user}.programs = {
    git = {
      enable = true;
      ignores = [ "*.swp" ];
      lfs.enable = true;
      settings = {
        user = {
          name = "Joel DSouza";
          email = "joeldsouzax@gmail.com";
        };
        init.defaultBranch = "main";
        core = {
          editor = "emacs";
          autocrlf = "input";
        };
        commit.gpgsign = true;
        pull.rebase = true;
        rebase.autoStash = true;
      };
    };
    # Delta (pager for git diffs) — renamed from git.delta to programs.delta
    delta.enable = true;
  };
}
