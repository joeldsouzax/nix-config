# Docker
#

{ pkgs, vars, ... }:

{
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };
  users.groups.docker.members = [ "${vars.user}" ];
  environment.systemPackages = with pkgs; [ podman podman-compose ];
}
