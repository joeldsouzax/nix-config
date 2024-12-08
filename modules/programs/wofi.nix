# System Menu
#

{ config, lib, pkgs, vars, ... }:

let colors = import ../theming/colors.nix;
in {
  config = lib.mkIf (config.wlwm.enable) {
    home-manager.users.${vars.user} = {
      home = { packages = with pkgs; [ wofi ]; };

      home.file = with colors.scheme.default.hex; {
        ".config/wofi/config" = {
          text = ''
            width=100%
            height=36
            xoffset=0
            yoffset=-36
            location=1
            prompt=Search...
            filter_rate=100
            allow_markup=false
            no_actions=true
            halign=fill
            orientation=horizontal
            content_halign=fill
            insensitive=true
            allow_images=true
            image_size=18
            hide_scroll=true
          '';
        };
        ".config/wofi/style.css" = {
          text = ''
            window {
              background-color: #${bg};
            }

            #input {
              border-radius: 6px;
              padding-right: 5px;
              color: #${text};
              background-color: #${bg};
            }

            #outer-box {
              border: none;

            }

            #inner-box {
              padding: none;
            }

            #text:selected {
              /*color: rgba(255, 255, 255, 0.8);*/
              /*color: rgba(0, 0, 0, 0.8);*/
            }

            #entry {
              color: #${text};
              padding-right: 5px;
            }

            #entry:selected {
              border-radius: 6px;
              background-color: #${active};
              padding-right: 5px;
            }

            #img {
              padding-right: 5px;
              padding-left: 5px;
            }
          '';
        };
        ".config/wofi/power.sh" = {
          executable = true;
          text = ''
            #!/bin/sh

            entries="󰍃 Logout\n󰒲 Suspend\n Reboot\n⏻ Shutdown"

            selected=$(echo -e $entries|wofi --dmenu --cache-file /dev/null | awk '{print tolower($2)}')

            case $selected in
              logout)
                exec hyprctl dispatch exit;;
              suspend)
                exec systemctl suspend;;
              reboot)
                exec systemctl reboot;;
              shutdown)
                exec systemctl poweroff -i;;
            esac
          '';
        };
      };
    };
  };
}
