{ config, lib, pkgs, hyprland, hyprspace, vars, host, ... }:

let
  colors = import ../theming/colors.nix;
  lid = "LID";
  # 1. Define Common Variables separately for cleaner reading
  commonEnv = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XCURSOR = "Catppuccin-Mocha-Dark-Cursors";
    XCURSOR_SIZE = "24";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  # 2. Nvidia specific variables
  nvidiaEnv = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
    GBM_BACKEND = "nvidia";
  };

in with lib;
with host; {
  options.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf config.hyprland.enable {
    wlwm.enable = true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = hyprland.packages.${pkgs.system}.hyprland;
    };

    # Initialize Environment
    environment = {
      # loginShellInit = ''
      #   if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      #     exec uwsm start hyprland-uwsm.desktop
      #   fi
      # '';

      variables = commonEnv;

      # Merge Common + Nvidia if hostname matches
      sessionVariables =
        if hostname == "main" then (commonEnv // nvidiaEnv) else commonEnv;

      systemPackages = with pkgs; [
        grimblast
        hyprcursor
        hyprpaper
        wl-clipboard
        wlr-randr
        xwayland
        nwg-look
        uwsm
      ];
    };

    # System Integration
    security.pam.services.hyprlock = {
      text = "auth include login";
      fprintAuth = false;
      enableGnomeKeyring = true;
    };
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
          user = vars.user;
        };

        initial_session = {
          command = "${pkgs.uwsm}/bin/uwsm start hyprland-uwsm.desktop";
          user = vars.user;
        };
      };
    };

    # Home Manager Configuration
    home-manager.users.${vars.user} = {
      imports = [ hyprland.homeManagerModules.default ];

      # Enable services here instead of exec-once for better reliability
      services.hypridle.enable = true;
      services.hyprpaper.enable = true;

      # Note: Ensure you have services.waybar.enable = true; in your waybar module
      # Note: Ensure you have services.swaync.enable = true; in your swaync module

      wayland.windowManager.hyprland = with colors.scheme.default.hex; {
        enable = true;
        package = hyprland.packages.${pkgs.system}.hyprland;
        xwayland.enable = true;
        systemd.enable = false;

        settings = {

          xwayland = { force_zero_scaling = true; };
          # Monitor Configuration
          monitor = [
            # Main Monitor: 4K @ 1.5x Scale (Fixes "too low" font size)
            "${toString mainMonitor},3840x2160@60,0x0,1.5"
            # Second Monitor: Right of Main, Auto resolution
            "${toString secondMonitor},preferred,2560x0,auto,transform,1"
            # Fallback
            ",preferred,auto,1"
          ];

          debug = {
            disable_logs = false;
            enable_stdout_logs = true;
          };

          # THIS IS THE FIX
          # It tells Hyprland "I know what I'm doing, stop checking for the wrapper"
          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;

            # The "shut up about start-hyprland" switch
            # (Note: In some versions this might be 'disable_watchdog_warning')
            disable_hyprland_qtutils_check = true;
          };

          general = {
            border_size = 1;
            gaps_in = 1;
            gaps_out = 1;
            "col.active_border" = "0x99${active}";
            "col.inactive_border" = "0x66${inactive}";
            resize_on_border = true;
            layout = "dwindle";
          };

          decoration = {
            rounding = 3;
            active_opacity = 1.0;
            inactive_opacity = 1.0;
            fullscreen_opacity = 1.0;

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              vibrancy = 0.1696;
            };
          };

          animations = {
            enabled = true;
            bezier =
              [ "fast, 0, 0.55, 0.45, 1" "snappy, 0.05, 0.9, 0.1, 1.05" ];

            animation = [
              "windows, 1, 3, snappy"
              "windowsOut, 1, 3, snappy, popin 80%"
              "border, 1, 2, fast"
              "fade, 1, 2, fast"
              "workspaces, 1, 3, snappy"
            ];
          };

          misc = {
            vfr = true;
            vrr = 1;
          };

          workspace =
            (map (i: "${toString i}, monitor:${toString mainMonitor}") [
              1
              2
              3
              4
            ]) ++ (map (i: "${toString i}, monitor:${toString secondMonitor}") [
              5
              6
              7
              8
              9
            ]);

          input = {
            kb_layout = "us";
            kb_options = "caps:escape";
            follow_mouse = 2;
            numlock_by_default = 1;
            accel_profile = "flat";
            sensitivity = 0.8;
          };

          cursor.no_hardware_cursors = true;

          # Keybindings
          bind = let
            # Helper to generate workspace bindings
            workspaces =
              [ "1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "left" "right" ];
            # Map over workspaces to generate ALT+X and ALT+SHIFT+X
            workspaceBindings = map (k:
              if (k == "left" || k == "right") then
                "ALT,${k},workspace,${if k == "left" then "-1" else "+1"}"
              else
                "ALT,${k},workspace,${k}") workspaces;
            moveBindings = map (k:
              if (k == "left" || k == "right") then
                "ALTSHIFT,${k},movetoworkspace,${
                  if k == "left" then "-1" else "+1"
                }"
              else
                "ALTSHIFT,${k},movetoworkspace,${k}") workspaces;
          in [
            "SUPER,Return,exec,${pkgs.${vars.terminal}}/bin/${vars.terminal}"
            "SUPER,Q,killactive,"
            "SUPER,Escape,exec,uwsm stop"
            "SUPER,L,exec,${pkgs.hyprlock}/bin/hyprlock"
            "SUPER,E,exec,${pkgs.pcmanfm}/bin/pcmanfm"
            "SUPER,F,togglefloating,"
            "SUPER,Space,exec, pkill wofi || ${pkgs.wofi}/bin/wofi --show drun"
            "SUPER,P,pseudo,"
            ",F11,fullscreen,"
            "SUPERSHIFT,R,exec,hyprctl reload"

            # Focus/Move
            "SUPER,left,movefocus,l"
            "SUPER,right,movefocus,r"
            "SUPER,up,movefocus,u"
            "SUPER,down,movefocus,d"
            "SUPERSHIFT,left,movewindow,l"
            "SUPERSHIFT,right,movewindow,r"
            "SUPERSHIFT,up,movewindow,u"
            "SUPERSHIFT,down,movewindow,d"

            # Audio / Brightness
            ",print,exec,${pkgs.grimblast}/bin/grimblast --notify --freeze --wait 1 copysave area ~/Pictures/$(date +%Y-%m-%dT%H%M%S).png"
            ",XF86AudioLowerVolume,exec,${pkgs.pamixer}/bin/pamixer -d 10"
            ",XF86AudioRaiseVolume,exec,${pkgs.pamixer}/bin/pamixer -i 10"
            ",XF86AudioMute,exec,${pkgs.pamixer}/bin/pamixer -t"
          ] ++ workspaceBindings ++ moveBindings;

          # Startup
          exec-once = [
            "${pkgs.hyprlock}/bin/hyprlock"
            "ln -s $XDG_RUNTIME_DIR/hypr /tmp/hypr"
            "uwsm app -- ${pkgs.waybar}/bin/waybar -c $HOME/.config/waybar/config"
            "uwsm app -- ${pkgs.swaynotificationcenter}/bin/swaync"
            "uwsm app -- ${pkgs.blueman}/bin/blueman-applet"

            "hyprctl dispatch workspace 1"
          ];
        };
      };

      # Keep your existing file/script definitions
      home.file.".config/hypr/script/clamshell.sh" = {
        executable = true;
        text = ''
          #!/bin/sh
          if grep open /proc/acpi/button/lid/${lid}/state; then
            ${config.programs.hyprland.package}/bin/hyprctl keyword monitor "${
              toString mainMonitor
            }, 3840x2160, 0x0, 1.5"
          else
            # ... (rest of your script)
          fi
        '';
      };
    };
  };
}
