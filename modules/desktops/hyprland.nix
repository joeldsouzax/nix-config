{
  config,
  lib,
  pkgs,
  hyprland,
  hyprspace,
  vars,
  host,
  ...
}:

let
  colors = import ../theming/colors.nix;
  lid = "LID";
  commonEnv = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1"; # This fixes the Electron apps
    GDK_BACKEND = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
    XCURSOR = "Catppuccin-Mocha-Dark-Cursors";
    XCURSOR_SIZE = "24";
  };

  # 2. Nvidia variables — SINGLE-GPU DESKTOP (not a hybrid/Optimus laptop).
  # Per the official Hyprland Nvidia wiki, only these three are needed. The
  # previous config also set PRIME render-offload vars
  # (__NV_PRIME_RENDER_OFFLOAD, __NV_PRIME_RENDER_OFFLOAD_PROVIDER,
  # __VK_LAYER_NV_optimus) and GBM_BACKEND — those are for Optimus LAPTOPS
  # (iGPU→dGPU offload) and break a single-GPU desktop. Removed.
  nvidiaEnv = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct"; # HW video accel (via nvidia-vaapi-driver)
  };

in
with lib;
with host;
{
  options.hyprland.enable = mkEnableOption "Hyprland";

  config = mkIf config.hyprland.enable {
    wlwm.enable = true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    };

    # Validate the file read by this compositor before allowing activation.
    system.build.hyprlandCheck = import ../../tests/hyprland.nix {
      inherit pkgs;
      home = config.home-manager.users.${vars.user};
    };
    system.checks = [ config.system.build.hyprlandCheck ];

    # Initialize Environment
    environment = {
      # loginShellInit = ''
      #   if [ -z $DISPLAY ] && [ "$(tty)" = "/dev/tty1" ]; then
      #     exec uwsm start hyprland-uwsm.desktop
      #   fi
      # '';

      variables = commonEnv;

      # Merge Common + Nvidia if hostname matches
      sessionVariables = if hostname == "main" then (commonEnv // nvidiaEnv) else commonEnv;

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
        package = hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        configType = "lua";
        xwayland.enable = true;
        systemd.enable = false;

        settings = {

          # Monitor Configuration — single 4K panel (3840x2160@60).
          # Scale 1: maximum real estate on the large screen (1.5x would defeat
          # the point). If the panel enumerates on a port other than
          # `mainMonitor`, update it in hosts/default.nix — the wildcard below
          # still drives the display in the meantime.
          monitor = [
            {
              output = toString mainMonitor;
              mode = "3840x2160@60";
              position = "0x0";
              scale = 1;
            }
            # Fallback for a differently-named / hotplugged output.
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ];

          config = {
            xwayland.force_zero_scaling = true;
            debug = {
              disable_logs = true; # logging adds overhead — off for fluidity
              enable_stdout_logs = false;
              # vfr moved misc: -> debug: in Hyprland 0.55. Skips rendering idle
              # frames (big power/perf win when nothing's animating).
              vfr = true;
            };

            misc = {
              disable_hyprland_logo = true;
              disable_splash_rendering = true;
              # (misc:vrr omitted: it does nothing on a fixed 60Hz panel. It still
              # exists globally, and is also settable per-monitor via monitorv2.)
            };

            general = {
              border_size = 1;
              gaps_in = 1;
              gaps_out = 1;
              col.active_border = "rgba(${active}99)";
              col.inactive_border = "rgba(${inactive}66)";
              resize_on_border = true;
              layout = "dwindle";
              allow_tearing = true; # lets games bypass vsync (with immediate windowrule) — lower latency
            };

            decoration = {
              rounding = 3;
              active_opacity = 1.0;
              inactive_opacity = 1.0;
              fullscreen_opacity = 1.0;

              blur = {
                enabled = true;
                size = 2; # smaller radius — cheaper on a 4K panel
                passes = 1;
                new_optimizations = true; # cache blur regions — big GPU win
                xray = true; # skip blurring content hidden behind windows
                vibrancy = 0.1696;
              };
            };

            animations.enabled = true;

            input = {
              kb_layout = "us";
              kb_options = "caps:escape";
              follow_mouse = 2;
              numlock_by_default = true;
              accel_profile = "flat";
              sensitivity = 0.8;
            };

            cursor.no_hardware_cursors = 1;
          };
        };

        extraConfig = ''
          hl.curve("fast", { type = "bezier", points = {{0, 0.55}, {0.45, 1}} })
          hl.curve("snappy", { type = "bezier", points = {{0.05, 0.9}, {0.1, 1.05}} })
          hl.animation({ leaf = "windows", enabled = true, speed = 3, bezier = "snappy" })
          hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "snappy", style = "popin 80%" })
          hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "fast" })
          hl.animation({ leaf = "fade", enabled = true, speed = 2, bezier = "fast" })
          hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "snappy" })

          -- SUPER is Command on the Mac keyboard attached to this desktop.
          hl.bind("SUPER + Return", hl.dsp.exec_cmd("${pkgs.${vars.terminal}}/bin/${vars.terminal}"))
          hl.bind("SUPER + Q", hl.dsp.window.close())
          hl.bind("SUPER + Escape", hl.dsp.exec_cmd("${pkgs.uwsm}/bin/uwsm stop"))
          hl.bind("SUPER + L", hl.dsp.exec_cmd("${pkgs.hyprlock}/bin/hyprlock"))
          hl.bind("SUPER + E", hl.dsp.exec_cmd("${pkgs.pcmanfm}/bin/pcmanfm"))
          hl.bind("SUPER + F", hl.dsp.window.float({ action = "toggle" }))
          hl.bind("SUPER + Space", hl.dsp.exec_cmd("${pkgs.procps}/bin/pkill -u ${vars.user} -x 'wofi|[.]wofi-wrapped' || ${pkgs.wofi}/bin/wofi --show drun"))
          hl.bind("SUPER + D", hl.dsp.exec_cmd("${
            config.home-manager.users.${vars.user}.programs.ags.finalPackage
          }/bin/ags toggle dashboard"))
          hl.bind("SUPER + P", hl.dsp.window.pseudo())
          hl.bind("F11", hl.dsp.window.fullscreen())
          hl.bind("SUPER + SHIFT + R", hl.dsp.exec_cmd("${config.programs.hyprland.package}/bin/hyprctl reload"))

          for _, direction in ipairs({"left", "right", "up", "down"}) do
            hl.bind("SUPER + " .. direction, hl.dsp.focus({ direction = direction }))
            hl.bind("SUPER + SHIFT + " .. direction, hl.dsp.window.move({ direction = direction }))
          end

          for workspace = 1, 10 do
            local key = workspace % 10
            hl.workspace_rule({ workspace = tostring(workspace), monitor = ${
              lib.generators.toLua { } (toString mainMonitor)
            }, default = workspace == 1 })
            hl.bind("ALT + " .. key, hl.dsp.focus({ workspace = workspace }))
            hl.bind("ALT + SHIFT + " .. key, hl.dsp.window.move({ workspace = workspace }))
          end
          for direction, workspace in pairs({left = "-1", right = "+1"}) do
            hl.bind("ALT + " .. direction, hl.dsp.focus({ workspace = workspace }))
            hl.bind("ALT + SHIFT + " .. direction, hl.dsp.window.move({ workspace = workspace }))
          end

          hl.bind("Print", hl.dsp.exec_cmd("${pkgs.grimblast}/bin/grimblast --notify --freeze --wait 1 copysave area ~/Pictures/$(date +%Y-%m-%dT%H%M%S).png"))
          hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${pkgs.pamixer}/bin/pamixer -d 10"))
          hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${pkgs.pamixer}/bin/pamixer -i 10"))
          hl.bind("XF86AudioMute", hl.dsp.exec_cmd("${pkgs.pamixer}/bin/pamixer -t"))

          hl.on("hyprland.start", function()
            hl.exec_cmd("${pkgs.hyprlock}/bin/hyprlock")
            hl.exec_cmd("ln -s $XDG_RUNTIME_DIR/hypr /tmp/hypr")
            hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${pkgs.waybar}/bin/waybar -c $HOME/.config/waybar/config")
            hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${pkgs.swaynotificationcenter}/bin/swaync")
            hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${pkgs.blueman}/bin/blueman-applet")
            hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -- ${
              config.home-manager.users.${vars.user}.programs.ags.finalPackage
            }/bin/ags run")
            hl.dispatch(hl.dsp.focus({ workspace = 1 }))
          end)
        '';
      };

      # Keep your existing file/script definitions
      home.file.".config/hypr/script/clamshell.sh" = {
        executable = true;
        text = ''
          #!/bin/sh
          if grep open /proc/acpi/button/lid/${lid}/state; then
            ${config.programs.hyprland.package}/bin/hyprctl keyword monitor "${toString mainMonitor}, 3840x2160, 0x0, 1.5"
          else
            # ... (rest of your script)
          fi
        '';
      };
    };
  };
}
