# Direnv Configuration
# Shared between NixOS and Darwin via home-manager

{ vars, ... }:

{
  home-manager.users.${vars.user}.programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };
}
