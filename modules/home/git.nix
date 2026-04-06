# Git Configuration
# Shared between NixOS and Darwin via home-manager

{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user} = {
    # Trive work git identity — included conditionally via gitdir
    home.file.".config/git/trive.inc".text = ''
      [user]
        name = trivejoel
        email = joel@trive.ai
    '' + (if pkgs.stdenv.isLinux then ''
      [user]
        signingkey = 670C107333D4DECD
      [commit]
        gpgsign = true
    '' else ''
      [user]
        signingkey = 78A9307CC53445F1
      [commit]
        gpgsign = true
    '') + ''
      [url "git@github.com-trive:"]
        insteadOf = git@github.com:
    '';

    programs.git = {
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

        # Trive work account — repos under ~/Code/trive/
        "includeIf \"gitdir:~/Code/trive/\"" = {
          path = "~/.config/git/trive.inc";
        };
      };
      signing = {
        key = if pkgs.stdenv.isDarwin then "273FCD808A01AF59" else "2CE4286073195A43";
      };
    };
    # Delta (pager for git diffs) — renamed from git.delta to programs.delta
    programs.delta.enable = true;
  };
}
