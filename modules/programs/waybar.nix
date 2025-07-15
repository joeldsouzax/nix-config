# Bar
#

{ config, lib, pkgs, vars, host, ... }:
let colors = import ../theming/colors.nix;
in with host;
let
  output = [ mainMonitor secondMonitor ];
  modules-left = with config;
    if hyprland.enable == true then [
      "custom/menu"
      "hyprland/workspaces"
    ] else if sway.enable == true then [
      "sway/workspaces"
      "sway/window"
      "sway/mode"
    ] else
      [ ];

  modules-right = [
    "custom/ds4"
    "custom/mouse"
    "custom/kb"
    "custom/pad"
    "network"
    "cpu"
    "memory"
    "custom/pad"
    "pulseaudio"
    "custom/sink"
    "custom/pad"
    "clock"
    "tray"
    "custom/notification"
  ];

  sinkBuiltIn = "Built-in Audio Analog Stereo";
  sinkVideocard =
    "Ellesmere HDMI Audio \\[Radeon RX 470\\/480 \\/ 570\\/580\\/590\\] Digital Stereo \\(HDMI 3\\)";
  sinkBluetooth = "S10 Bluetooth Speaker";
  headset = sinkBuiltIn;
  speaker = sinkBluetooth;
in {
  config = lib.mkIf (config.wlwm.enable) {
    environment.systemPackages = with pkgs; [ waybar ];

    home-manager.users.${vars.user} = with colors.scheme.default; {
      programs.waybar = {
        enable = true;
        package = pkgs.waybar;
        style = ''
          * {
            border: none;
            border-radius: 0;
            font-family: FiraCode Nerd Font Mono;
            font-size: 18px;
          }

          window#waybar {
            background-color: transparent; /* Make the bar invisible */
          }

          /* Style for our status dots */
          #network, #custom-notification {
            padding: 0 5px; /* Add some spacing around the dots */
            color: transparent; /* Hide any default text */
          }
        '';

        settings = {
          Main = {
            layer = if config.hyprland.enable then "top" else "bottom";
            position = "top";
            height = 20;
            exclusive = false; # Don't reserve space on the screen
            passthrough =
              true; # Allow clicks to "pass through" the transparent bar
            modules-left = [ ];

            # Only show network and notification modules on the right
            modules-right = [ "network" "custom/notification" ];

            # --- MODULE CONFIGURATIONS ---

            "network" = {
              # Show a blue dot when WiFi is connected
              format-wifi = "<span foreground='blue'>●</span>";

              # Show nothing if disconnected or on another connection type
              format-ethernet = "";
              format-linked = "";
              format-disconnected = "";
              tooltip = false; # Disable tooltip popup on hover
            };

            "custom/notification" = {
              tooltip = false;
              format = "{icon}";
              format-icons = {
                # Show a red dot when there is a notification
                "notification" = "<span foreground='red'>●</span>";
                "dnd-notification" = "<span foreground='red'>●</span>";
                "inhibited-notification" = "<span foreground='red'>●</span>";
                "dnd-inhibited-notification" =
                  "<span foreground='red'>●</span>";

                # Show nothing when there are no notifications
                "none" = "";
                "dnd-none" = "";
                "inhibited-none" = "";
                "dnd-inhibited-none" = "";
              };
              return-type = "json";
              exec-if = "which swaync-client";
              exec = "swaync-client -swb";
              on-click = "sleep 0.1; swaync-client -t -sw";
              on-click-right = "sleep 0.1; swaync-client -d -sw";
              escape = true;
            };
          };
        };
      };
      home.file = {
        ".config/waybar/script/sink.sh" = {
          text = ''
            #!/bin/sh

            HEAD=$(awk '/ ${headset}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)
            SPEAK=$(awk '/ ${speaker}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)

            if [[ $SPEAK = "*" ]]; then
              printf "<span font='10'>󰓃</span>\n"
            elif [[ $HEAD = "*" ]]; then
              printf "<span font='13'></span>\n"
            fi
            exit 0
          '';
          executable = true;
        };
        ".config/waybar/script/switch.sh" = {
          text = ''
            #!/bin/sh

            ID1=$(awk '/ ${headset}/ {sub(/.$/,"",$2); print $2 }' <(${pkgs.wireplumber}/bin/wpctl status) | head -n 1)
            ID2=$(awk '/ ${speaker}/ {sub(/.$/,"",$2); print $2 }' <(${pkgs.wireplumber}/bin/wpctl status) | sed -n 2p)

            HEAD=$(awk '/ ${headset}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)
            SPEAK=$(awk '/ ${speaker}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)

            if [[ $SPEAK = "*" ]]; then
              ${pkgs.wireplumber}/bin/wpctl set-default $ID1
            elif [[ $HEAD = "*" ]]; then
              ${pkgs.wireplumber}/bin/wpctl set-default $ID2
            fi
            exit 0
          '';
          executable = true;
        };
        ".config/waybar/script/mouse.sh" = {
          text = ''
            #!/bin/sh

            for cap in /sys/class/power_supply/hidpp_battery_*/capacity; do
              BATT=$(cat "$cap")
            done
            for stat in /sys/class/power_supply/hidpp_battery_*/status; do
              STAT=$(cat "$stat")
            done

            if [[ "$STAT" = "Charging" ]] then
              printf "<span font='11'> 󰍽</span><span font='9'></span> $BATT%%\n"
            elif [[ "$STAT" = "Full" ]] then
              printf "<span font='11'> 󰍽</span><span font='9'></span> Full\n"
            elif [[ "$STAT" = "Discharging" ]] then
              printf "<span font='11'> 󰍽</span> $BATT%%\n"
            else
              printf "\n"
            fi

            exit 0
          '';
          executable = true;
        };
        ".config/waybar/script/kb.sh" = {
          text = ''
            #!/bin/sh

            for cap in /sys/class/power_supply/hid-dc:2c:26:36:79:9b-battery/capacity; do
              BATT=$(cat "$cap")
            done
            for stat in /sys/class/power_supply/hid-dc:2c:26:36:79:9b-battery/status; do
              STAT=$(cat "$stat")
            done

            if [[ "$STAT" == "Charging" ]] then
              printf "<span font='14'> 󰌌</span><span font='9'></span> $BATT%%\n"
            elif [[ "$STAT" == "Full" ]] then
              printf "<span font='14'> 󰌌</span><span font='9'></span> Full\n"
            elif [[ "$STAT" = "Discharging" ]] then
              printf "<span font='14'> 󰌌</span> $BATT%%\n"
            else
              printf "\n"
            fi

            exit 0
          '';
          executable = true;
        };
        ".config/waybar/script/ds4.sh" = {
          text = ''
            #!/bin/sh

            for cap in /sys/class/power_supply/*e8:47:3a:05:c0:2b/capacity; do
              BATT=$(cat "$cap")
            done
            for stat in /sys/class/power_supply/*e8:47:3a:05:c0:2b/status; do
              STAT=$(cat "$stat")
            done

            if [[ "$STAT" == "Charging" ]] then
              printf "<span font='14'> 󰊴</span><span font='9'></span> $BATT%%\n"
            elif [[ "$STAT" == "Full" ]] then
              printf "<span font='14'> 󰊴</span><span font='9'></span> Full\n"
            elif [[ "$STAT" = "Discharging" ]] then
              printf "<span font='14'> 󰊴</span> $BATT%%\n"
            else
              printf "\n"
            fi
            exit 0
          '';
          executable = true;
        };
      };
    };
  };
}
