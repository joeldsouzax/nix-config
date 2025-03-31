{ pkgs, lib, ... }: {
  home = {
    enableNixpkgsReleaseCheck = false;
    packages = with pkgs; [ fd curl ];
    stateVersion = "23.11";
  };

  home.sessionVariables = {
    PAGER = "less";
    CLICOLOR = 1;
    EDITOR = "emacs";
  };
  programs.bat.enable = true;
  programs.bat.config.theme = "TwoDark";
  programs.fzf.enable = true;
  programs.fzf.enableZshIntegration = true;
  programs.eza.enable = true;

  programs.dircolors = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    cdpath = [ "~/.local/share/src" ];
    dirHashes = { code = "$HOME/Code"; };

    shellAliases = {
      nixswitch = "darwin-rebuild switch --flake ~/.config/nix-darwin";
      nixup = "pushd ~/.config/nix-darwin; nix flake update; nixswitch; popd";
      search = ''rg -p --glob "!node_modules/*" --glob "!vendor/*" "$@"'';
      ls = "ls --color=auto";
    };

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./dotFiles;
        file = "p10k.zsh";
      }
    ];

    initExtraFirst = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      export LANG=en_US.UTF-8

      bindkey '^ ' autosuggest-accept

      # Define variables for directories
      export PATH=$HOME/.local/share/bin:$PATH
      export PATH="/opt/homebrew/bin:$PATH"
      export PATH="/opt/homebrew/sbin:$PATH"

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"
    '';
  };

  programs.git = {
    enable = true;
    ignores = [ "*.swp" ];
    delta.enable = true;
    userName = "Joel DSouza";
    userEmail = "joeldsouzax@gmail.com";
    lfs = { enable = true; };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      commit.gpgsign = true;
      pull.rebase = true;
      rebase.autoStash = true;
      extraConfig = { credential.helper = "oauth"; };
    };
  };

  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;

}
