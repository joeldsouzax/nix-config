# Docker
#

{ pkgs, vars, ... }:

{
  virtualisation = { podman.enable = true; };

  users.groups.docker.members = [ "${vars.user}" ];

  environment.systemPackages = with pkgs; [ podman podman-compose ];
}
