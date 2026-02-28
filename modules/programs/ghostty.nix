# NixOS System-Level Ghostty
# Home-manager config (settings, theme) moved to modules/home/ghostty.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ ghostty ];
}
