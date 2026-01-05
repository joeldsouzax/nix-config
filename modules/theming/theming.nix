{ lib, config, pkgs, host, vars, ... }:

let
  themeName = "Catppuccin-Mocha-Standard-Blue-Dark";
  themePackage = pkgs.catppuccin-gtk.override {
    accents = [ "blue" ];
    size = "standard";
    variant = "mocha";
  };

  cursorName = "Bibata-Modern-Ice";
  cursorPackage = pkgs.bibata-cursors;
  cursorSize = 24;

in {
  home-manager.users.${vars.user} = {
    home.file = {
      ".config/wall.png".source = ./pure-black.jpg;
      ".config/wall.mp4".source = ./wall.mp4;
    };

    home.pointerCursor = {
      gtk.enable = true;
      x11.enable = true;
      name = cursorName;
      package = cursorPackage;
      size = cursorSize;
    };

    gtk = lib.mkIf (!config.gnome.enable) {
      enable = true;

      theme = {
        name = themeName;
        package = themePackage;
      };

      iconTheme = {
        name = "Papirus-Dark";
        package = pkgs.papirus-icon-theme;
      };

      cursorTheme = {
        name = cursorName;
        package = cursorPackage;
        size = cursorSize;
      };

      font = {
        name = "Inter";
        package = pkgs.google-fonts;
        size = 11;
      };

      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-button-images = 1;
        gtk-decoration-layout = "icon:minimize,maximize,close";
      };

      gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    };

    qt = {
      enable = true;
      platformTheme.name = "gtk"; # Syncs Qt dialogs with GTK
      style = {
        name =
          "kvantum"; # Requires 'qt5ct' and 'libsForQt5.qtstyleplugin-kvantum' in system packages
      };
    };

    # 5. Kvantum Configuration (The bridge for Qt apps to look like Catppuccin)
    # This writes the config to make Kvantum use the Catppuccin theme
    xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
      [General]
      theme=Catppuccin-Mocha-Blue
    '';

    # Optional: Source the Catppuccin Kvantum theme if not installed system-wide
    xdg.configFile."Kvantum/Catppuccin-Mocha-Blue".source =
      "${pkgs.catppuccin-kvantum}/share/Kvantum/Catppuccin-Mocha-Blue";
  };
}
