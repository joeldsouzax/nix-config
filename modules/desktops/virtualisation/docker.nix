# Docker
#

{ pkgs, vars, ... }:

{
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
  };
  users.groups.docker.members = [ "${vars.user}" ];
  environment.systemPackages = with pkgs; [ docker docker-compose ];
}
