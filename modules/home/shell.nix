# Shell Configuration (ZSH + Nushell)
# Shared between NixOS and Darwin via home-manager
#
# ZSH: Spaceship prompt + Oh-My-Zsh (matches NixOS system-level config)
# Nushell: Primary shell inside Ghostty

{ config, lib, pkgs, vars, ... }:

let
  # Safely check if SOPS claude_key secret exists (NixOS only)
  claudeKeyPath = lib.attrByPath [ "sops" "secrets" "claude_key" "path" ] "" config;
in
{
  home-manager.users.${vars.user} = {
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      history.size = 100000;

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };

      # Modern HM uses unified initContent with ordering via mkBefore/mkAfter
      initContent = lib.mkMerge [
        # Early init (runs first)
        (lib.mkBefore (''
          # Nix daemon (needed on Darwin, harmless on NixOS)
          if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
            . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
          fi

          export LANG=en_US.UTF-8
          bindkey '^ ' autosuggest-accept
          export HISTIGNORE="pwd:ls:cd"
        '' + lib.optionalString pkgs.stdenv.isDarwin ''
          # Homebrew paths (Darwin only)
          export PATH="/opt/homebrew/bin:$PATH"
          export PATH="/opt/homebrew/sbin:$PATH"
          # SOPS age key location (Darwin — on NixOS, sops-nix manages this)
          export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"
        ''))

        # Main init (default order)
        ''
          # Spaceship prompt (same on NixOS and Darwin)
          source ${pkgs.spaceship-prompt}/share/zsh/site-functions/prompt_spaceship_setup
          autoload -U promptinit; promptinit
        ''
      ];

      shellAliases = {
        ls = "ls --color=auto";
        search = ''rg -p --glob "!node_modules/*" --glob "!vendor/*" "$@"'';
      } // (if pkgs.stdenv.isDarwin then {
        nixswitch = "sudo darwin-rebuild switch --flake ~/.setup#joel";
        nixup = "pushd ~/.setup; nix flake update; nixswitch; popd";
      } else {
        rebuild = "sudo nixos-rebuild switch --flake .#main";
      });
    };

    programs.nushell = {
      enable = true;
      configFile.text = ''
        $env.config = {
          show_banner: false,
          edit_mode: emacs
          ls: { use_ls_colors: true, clickable_links: true }
          table: { mode: rounded }
        }
        # Aliases
        alias ll = ls -l
        alias la = ls -a
        alias cat = bat
        alias find = fd
        alias grep = rg
        alias de = doom env
        alias ds = doom sync
      '' + (if pkgs.stdenv.isDarwin then ''
        def nixswitch [] { sudo darwin-rebuild switch --flake ~/.setup#joel }
      '' else ''
        def nixswitch [] { sudo nixos-rebuild switch --flake /home/${vars.user}/.setup#main }
      '') + lib.optionalString (claudeKeyPath != "") ''

        if ("${claudeKeyPath}" | path exists) {
            $env.ANTHROPIC_API_KEY = (open --raw "${claudeKeyPath}" | str trim)
        }
      '';
      envFile.text = ''
        $env.PATH = ($env.PATH | split row (char esep)
          | prepend "/etc/profiles/per-user/${vars.user}/bin"
          | prepend "/run/current-system/sw/bin"
          | prepend "/nix/var/nix/profiles/default/bin"
        ${
          if pkgs.stdenv.isDarwin then
            ''| prepend "/opt/homebrew/bin"''
          else
            # NixOS setuid wrappers (sudo, mount, ...) MUST win over the
            # non-setuid copies in /run/current-system/sw/bin — prepend last so
            # it lands at the front of PATH. Without this, `sudo` errors with
            # "must be owned by uid 0 and have the setuid bit set".
            ''| prepend "/run/wrappers/bin"''
        }
          | uniq)

        # 1Password SSH agent. securities.nix only exports SSH_AUTH_SOCK via
        # environment.extraInit (/etc/profile) — which POSIX login shells read
        # but Nushell does NOT. Without mirroring it here, ssh / `git fetch`
        # over the 1Password agent works in zsh but fails in Nushell.
        let op_sock = ($env.HOME | path join ".1password/agent.sock")
        if ($op_sock | path exists) { $env.SSH_AUTH_SOCK = $op_sock }
      '';
      environmentVariables = {
        EDITOR = "vim";
      };
    };
  };
}
