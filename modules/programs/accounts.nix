# Gnome Control Manager
# Mainly used for online accounts
#

{ lib, pkgs, vars, host, ... }:

{
  config = lib.mkIf (host.hostname == "main") {
    environment.systemPackages = with pkgs; [
      gnome-control-center
      gnome-online-accounts
    ];

    services.gnome.gnome-keyring.enable = true;

    security.pam.services.gnomekey.enableGnomeKeyring = true;

    home-manager.users.${vars.user} = {
      xdg.desktopEntries.gnome-control-center = {
        name = "Control";
        exec =
          "env XDG_CURRENT_DESKTOP=GNOME ${pkgs.gnome-control-center}/bin/gnome-control-center";
      };

      programs = {
        accounts = {
          calendar = {
            ## TODO: complete calendar and email
            basePath = "Calendar";
            accounts.personal_gmail = {
              remote.type = "google_calendar";
              vdirsyncer = {
                enable = true;
                collections = [ "from a" ];
              };
            };
          };
        };
      };
    };
  };
}
