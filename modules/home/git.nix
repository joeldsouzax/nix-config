# Git Configuration
# Shared between NixOS and Darwin via home-manager.
#
# The Trive work identity (joel@trive.ai / trivejoel) is macOS-ONLY — the NixOS
# desktop is for devrandom work only, so trive leaves no trace there.

{ lib, pkgs, vars, ... }:

let
  isDarwin = pkgs.stdenv.isDarwin;
in
{
  home-manager.users.${vars.user} = {
    # Trive work git identity — macOS only. Included conditionally via gitdir
    # (~/Code/trive/) by the includeIf below.
    home.file = lib.mkIf isDarwin {
      ".config/git/trive.inc".text = ''
        [user]
          name = trivejoel
          email = joel@trive.ai
          signingkey = 78A9307CC53445F1
        [commit]
          gpgsign = true
        [url "git@github.com-trive:"]
          insteadOf = git@github.com:
      '';
    };

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
      }
      // lib.optionalAttrs isDarwin {
        # Trive work account — repos under ~/Code/trive/ (macOS only).
        "includeIf \"gitdir:~/Code/trive/\"" = {
          path = "~/.config/git/trive.inc";
        };
      };
      signing = {
        key = if isDarwin then "273FCD808A01AF59" else "2CE4286073195A43";
      };
    };
    # Delta (pager for git diffs) — renamed from git.delta to programs.delta
    programs.delta.enable = true;
  };
}
