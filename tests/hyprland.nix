{ pkgs, home }:
let
  compositor = home.wayland.windowManager.hyprland;
in
assert pkgs.lib.assertMsg (
  compositor.configType == "lua" && home.xdg.configFile."hypr/hyprland.lua".enable
) "Hyprland must receive its managed Lua configuration";
pkgs.runCommand "hyprland-configuration" { } ''
  export XDG_RUNTIME_DIR="$TMPDIR/runtime"
  export XDG_CONFIG_HOME="$TMPDIR/config"
  export XDG_CACHE_HOME="$TMPDIR/cache"
  mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
  mkdir -m 700 "$XDG_RUNTIME_DIR"
  timeout 30s ${compositor.finalPackage}/bin/Hyprland --verify-config \
    --config ${home.xdg.configFile."hypr/hyprland.lua".source}
  touch "$out"
''
