# Bspwm Configuration
#  Enable with "bspwm.enable = true;"
#

{ config, lib, pkgs, vars, host, ... }:

with lib;
with host;
let
  monitor =
    "${pkgs.xorg.xrandr}/bin/xrandr --output ${mainMonitor} --primary --mode 3840x2170 --rate 60 --pos 0x0 --rotate normal --output ${secondMonitor} --mode 1920x1080 --rate 60 --pos 0x0 --left-of ${mainMonitor}";
  extra = ''
    killall -q polybar &
    while pgrep -u $UID -x polybar >/dev/null; do sleep 1;done

    WORKSPACES

    bspc config border_width      3
    bspc config window_gaps       5
    bspc config split_ratio     0.5

    bspc config click_to_focus            true
    bspc config focus_follows_pointer     true
    bspc config borderless_monocle        false
    bspc config gapless_monocle           false

    #bspc config normal_border_color  "#000000"
    #bspc config focused_border_color "#ffffff"

    #pgrep -x sxhkd > /dev/null || sxhkd &

    feh --bg-tile $HOME/.config/wall.png

    polybar main & #2>~/log &
  '';

  extraConf = builtins.replaceStrings [ "WORKSPACES" ] [''
    bspc monitor ${secondMonitor} -d 1 2 3 4
    bspc monitor ${mainMonitor} -d 5 6 7 8 9
    bspc wm -O ${secondMonitor} ${mainMonitor}
    polybar sec &
    polybar thi &
  ''] "${extra}";
in {
  options = {
    bspwm = {
      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf (config.bspwm.enable) {
    x11wm.enable = true;

    services = {
      displayManager.defaultSession = "none+bspwm";
      libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          scrollMethod = "twofinger";
          naturalScrolling = true;
          accelProfile = "adaptive";
          disableWhileTyping = true;
        };
      };
      xserver = {
        enable = true;
        xkb = { layout = "us"; };
        autoRepeatInterval = 50;
        autoRepeatDelay = 200;
        modules = [ pkgs.xf86_input_wacom ];
        wacom.enable = true;

        displayManager = {
          lightdm = {
            enable = true;
            background =
              pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;
            greeters = {
              gtk = {
                theme = {
                  name = "Dracula";
                  package = pkgs.dracula-theme;
                };
                cursorTheme = {
                  name = "Dracula-cursors";
                  package = pkgs.dracula-theme;
                  size = 16;
                };
              };
            };
          };
        };
        windowManager.bspwm = { enable = true; };

        displayManager.sessionCommands = monitor;

        serverFlagsSection = ''
          Option "BlankTime" "0"
          Option "StandbyTime" "0"
          Option "SuspendTime" "0"
          Option "OffTime" "0"
        ''; # Disable Sleep

        resolutions = [
          {
            x = 1920;
            y = 1080;
          }
          {
            x = 1920;
            y = 1200;
          }
          {
            x = 1600;
            y = 900;
          }
          {
            x = 3840;
            y = 2160;
          }
        ];
      };
    };

    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      xclip # Clipboard
      xorg.xev # Event Viewer
      xorg.xkill # Process Killer
      xorg.xrandr # Monitor Settings

    ];

    home-manager.users.${vars.user} = {
      xsession = {
        enable = true;
        numlock.enable = true;
        windowManager = {
          bspwm = {
            enable = true;
            monitors = {
              ${mainMonitor} = [ "5" "6" "7" "8" "9" ];
              ${secondMonitor} = [ "1" "2" "3" "4" ];
            };
            rules = {
              # Window Rules (xprop)
              "Emacs" = {
                desktop = "2";
                follow = true;
                state = "tiled";
              };
              ".blueman-manager-wrapped" = {
                state = "floating";
                sticky = true;
              };
              "libreoffice" = {
                desktop = "3";
                follow = true;
              };
              "Lutris" = {
                desktop = "5";
                follow = true;
              };
              "Pavucontrol" = {
                state = "floating";
                sticky = true;
              };
              "Pcmanfm" = { state = "floating"; };
              "plexmediaplayer" = {
                desktop = "4";
                follow = true;
                state = "fullscreen";
              };
              "*:*:Picture in picture" = {
                state = "floating";
                sticky = true;
              };
              "*:*:Picture-in-Picture" = {
                state = "floating";
                sticky = true;
              };
              "Steam" = { desktop = "5"; };
            };
            extraConfig = extraConf;
          };
        };
      };
    };
  };
}
