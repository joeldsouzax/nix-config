# NixOS System-Level Programs
# Home-manager config (nushell, starship, etc.) moved to modules/home/
{
  config,
  pkgs,
  vars,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    nushell
  ];

  sops.secrets.claude_key = {
    owner = "joel";
    group = "users";
    mode = "0400";
  };
}
