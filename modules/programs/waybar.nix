{ config, lib, pkgs, vars, host, ... }:

let
  colors = import ../theming/colors.nix;

  # --- Device Definitions ---
  # Centralized hardware IDs for easier updates
  devices = {
    sinkBuiltIn = "Built-in Audio Analog Stereo";
    sinkVideocard =
      "Ellesmere HDMI Audio \\[Radeon RX 470\\/480 \\/ 570\\/580\\/590\\] Digital Stereo \\(HDMI 3\\)";
    sinkBluetooth = "S10 Bluetooth Speaker";

    # Paths for battery scripts
    mousePath = "/sys/class/power_supply/hidpp_battery_*";
    kbPath = "/sys/class/power_supply/hid-dc:2c:26:36:79:9b-battery";
    ds4Path = "/sys/class/power_supply/*e8:47:3a:05:c0:2b";
  };

  # --- Helper to generate battery scripts ---
  # Reduces duplicated logic for Mouse, KB, and DS4
  mkBatteryScript = { path, iconFont, iconFull ? "Full" }: ''
    #!/bin/sh
    for cap in ${path}/capacity; do BATT=$(cat "$cap"); done
    for stat in ${path}/status; do STAT=$(cat "$stat"); done

    if [[ "$STAT" == "Charging" ]]; then
      printf "<span font='${iconFont}'>⚡</span> $BATT%%\n"
    elif [[ "$STAT" == "Full" ]]; then
      printf "<span font='${iconFont}'>⚡</span> ${iconFull}\n"
    elif [[ "$STAT" == "Discharging" ]]; then
      printf "<span font='${iconFont}'>🔋</span> $BATT%%\n"
    else
      printf "\n"
    fi
    exit 0
  '';

  # --- Styling ---
  barStyle = ''
    * {
      border: none;
      border-radius: 0;
      font-family: FiraCode Nerd Font Mono;
      font-size: 18px;
    }

    window#waybar {
      background-color: transparent;
    }

    #network, #custom-notification {
      padding: 0 5px;
      color: transparent;
    }
  '';

in with host; {
  config = lib.mkIf (config.wlwm.enable) {
    environment.systemPackages = [ pkgs.waybar ];

    home-manager.users.${vars.user} = {
      programs.waybar = {
        enable = true;
        package = pkgs.waybar;
        style = barStyle;

        settings.Main = {
          layer = if config.hyprland.enable then "top" else "bottom";
          position = "top";
          height = 20;
          exclusive = false;
          passthrough = true;

          modules-left =
            [ ]; # Intentionally empty based on your original active config
          modules-right = [ "network" "custom/notification" ];

          # --- Modules ---
          "network" = {
            format-wifi = "<span foreground='blue'>●</span>";
            format-ethernet = "";
            format-linked = "";
            format-disconnected = "";
            tooltip = false;
          };

          "custom/notification" = {
            tooltip = false;
            format = "{icon}";
            format-icons = {
              notification = "<span foreground='red'>●</span>";
              dnd-notification = "<span foreground='red'>●</span>";
              inhibited-notification = "<span foreground='red'>●</span>";
              dnd-inhibited-notification = "<span foreground='red'>●</span>";
              none = "";
              dnd-none = "";
              inhibited-none = "";
              dnd-inhibited-none = "";
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

      # --- Scripts ---
      home.file = {
        # Battery Scripts generated via helper
        ".config/waybar/script/mouse.sh" = {
          executable = true;
          text = mkBatteryScript {
            path = devices.mousePath;
            iconFont = "11";
          };
        };
        ".config/waybar/script/kb.sh" = {
          executable = true;
          text = mkBatteryScript {
            path = devices.kbPath;
            iconFont = "14";
          };
        };
        ".config/waybar/script/ds4.sh" = {
          executable = true;
          text = mkBatteryScript {
            path = devices.ds4Path;
            iconFont = "14";
          };
        };

        # Audio Scripts
        ".config/waybar/script/sink.sh" = {
          executable = true;
          text = ''
            #!/bin/sh
            HEAD=$(awk '/ ${devices.sinkBuiltIn}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)
            SPEAK=$(awk '/ ${devices.sinkBluetooth}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)

            if [[ $SPEAK = "*" ]]; then
              printf "<span font='10'>🔊</span>\n"
            elif [[ $HEAD = "*" ]]; then
              printf "<span font='13'>🎧</span>\n"
            fi
            exit 0
          '';
        };

        ".config/waybar/script/switch.sh" = {
          executable = true;
          text = ''
            #!/bin/sh
            ID1=$(awk '/ ${devices.sinkBuiltIn}/ {sub(/.$/,"",$2); print $2 }' <(${pkgs.wireplumber}/bin/wpctl status) | head -n 1)
            ID2=$(awk '/ ${devices.sinkBluetooth}/ {sub(/.$/,"",$2); print $2 }' <(${pkgs.wireplumber}/bin/wpctl status) | sed -n 2p)

            HEAD=$(awk '/ ${devices.sinkBuiltIn}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)
            SPEAK=$(awk '/ ${devices.sinkBluetooth}/ { print $2 }' <(${pkgs.wireplumber}/bin/wpctl status | grep "*") | head -n 1)

            if [[ $SPEAK = "*" ]]; then
              ${pkgs.wireplumber}/bin/wpctl set-default $ID1
            elif [[ $HEAD = "*" ]]; then
              ${pkgs.wireplumber}/bin/wpctl set-default $ID2
            fi
            exit 0
          '';
        };
      };
    };
  };
}
