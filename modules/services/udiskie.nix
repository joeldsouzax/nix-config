#
#  Mounting tool
#

{ vars, ... }:

{
  services.udisks2.enable = true;
  home-manager.users.${vars.user} = {
    services = {
      udiskie = {
        enable = true;
        automount = true;
        tray = "auto";
      };
    };
  };
}
