# CLI Programs Configuration
# Shared between NixOS and Darwin via home-manager

{ pkgs, vars, ... }:

{
  home-manager.users.${vars.user}.programs = {
    # --- Prompts & Navigation ---
    starship = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableNushellIntegration = true;
      enableZshIntegration = true;
    };

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

    # --- File & Search Tools ---
    fzf = {
      enable = true;
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

    # --- Media ---
    gallery-dl = {
      enable = true;
      settings = {
        extractor.base-directory = "~/Downloads";
      };
    };
  };
}
