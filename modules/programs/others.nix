{
  config,
  pkgs,
  vars,
  ...
}:

let
  colors = import ../theming/colors.nix;
in
{

  environment.systemPackages = with pkgs; [
    ghostty
    nushell
  ];

  sops.secrets.claude_key = {
    owner = "joel";
    group = "users";
    mode = "0400";
  };

  home-manager.users.${vars.user} = {
    programs = {

      nushell = {
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
          alias rebuild = sudo nixos-rebuild switch --flake .#main
          alias de = doom env
          alias ds = doom sync

          if ("${config.sops.secrets.claude_key.path}" | path exists) {
              $env.CLAUDE_API_KEY = (open --raw "${config.sops.secrets.claude_key.path}" | str trim)
          }
        '';
        environmentVariables = {
          EDITOR = "emacsclient -t";
        };
      };

      # --- 3. Prompts & Tools ---
      starship = {
        enable = true;
        enableNushellIntegration = true; # <--- Upgrade
        enableZshIntegration = true;
      };

      # Replaces 'autojump' (Power User Standard)
      zoxide = {
        enable = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
      };

      # Replaces 'hstr' (Magical History)
      atuin = {
        enable = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
        flags = [ "--disable-up-arrow" ];
      };

      carapace = {
        enable = true;
        enableNushellIntegration = true;
      };

      fzf = {
        enable = true;
        # enableNushellIntegration = true;
        enableZshIntegration = true;
      };

      bat = {
        enable = true;
        config.theme = "TwoDark";
      };

      eza = {
        enable = true;
        enableNushellIntegration = true;
        colors = "always";
        git = true;
        icons = "always";
      };

      dircolors = {
        enable = true;
        enableNushellIntegration = true;
        enableZshIntegration = true;
      };

      gallery-dl = {
        enable = true;
        settings = {
          extractor.base-directory = "~/Downloads";
        };
      };
    };
  };
}
