# AGS v2 / Astal — desktop widgets & monitoring dashboard.
#
# programs.ags only SYMLINKS configDir to ~/.config/ags (it does not compile it
# at build time), so a bug in the widget code can never break `nixos-rebuild` —
# it only surfaces when the shell runs. Iterate live on the desktop:
#     ags run ~/.config/ags      # hot-reloads on save
#     ags init                   # (re)generate the official starter template
#
# The starter config in ./ags is a monitoring dashboard (CPU/RAM/disk/clock +
# a services panel). Treat it as a starting point — extend it with the Astal
# service libs wired in `extraPackages` below.

{ config, lib, pkgs, vars, inputs, ... }:

let
  agsPkgs = inputs.ags.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf config.wlwm.enable {
    home-manager.users.${vars.user} = {
      imports = [ inputs.ags.homeManagerModules.default ];

      programs.ags = {
        enable = true;
        configDir = ./ags;

        # Autostart as a user service. If the widget code is broken the service
        # fails, but the system rebuild still succeeds — safe by construction.
        systemd.enable = true;

        # Astal libraries available to the GJS runtime (import as "gi://Astal…").
        extraPackages = with agsPkgs; [
          astal4        # GTK4 layer-shell windows
          io            # subprocess + file IO (read /proc, run `systemctl`, curl)
          hyprland      # workspaces / active window
          network       # wifi / ethernet
          wireplumber   # audio
          tray          # system tray
          mpris         # media players
          battery       # harmless on desktop
          powerprofiles
        ];
      };
    };
  };
}
