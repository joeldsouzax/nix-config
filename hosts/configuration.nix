{ lib, config, pkgs, stable, inputs, vars, ... }:
let terminal = pkgs.${vars.terminal};
in {
  imports = (import ../modules/desktops ++ import ../modules/programs
    ++ import ../modules/services ++ import ../modules/shell
    ++ import ../modules/editors ++ import ../modules/theming);

  boot = {
    tmp = {
      cleanOnBoot = true;
      tmpfsSize = "5GB";
    };
  };

  users.users.${vars.user} = {
    isNormalUser = true;
    home = "/home/${vars.user}";
    extraGroups =
      [ "wheel" "video" "audio" "camera" "networkmanager" "lp" "scanner" ];
  };
  security.chromiumSuidSandbox.enable = true;

  environment.variables.VDPAU_DRIVER = "va_gl";
  environment.variables.LIBVA_DRIVER_NAME = "nvidia";

  time.timeZone = "Europe/Oslo";
  i18n = { defaultLocale = "en_US.UTF-8"; };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
  };

  fonts.packages = with pkgs; [
    carlito
    vegur
    source-code-pro
    jetbrains-mono
    font-awesome
    corefonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    # (nerdfonts.override { fonts = [ "FiraCode" ]; })
    nerd-fonts.fira-code
  ];

  services.udev.packages = [ pkgs.android-udev-rules ];

  environment = {
    variables = {
      TERMINAL = "${vars.terminal}";
      EDITOR = "${vars.editor}";
      VISUAL = "${vars.editor}";
    };
    sessionVariables = { NIXOS_OZONE_WL = "1"; };
    systemPackages = with pkgs;
      [
        # terminal
        terminal
        bat
        btop
        coreutils
        git
        gvfs
        cifs-utils
        killall
        nix-tree
        lshw
        pciutils
        usbutils
        ranger
        smartmontools
        wget
        xdg-utils

        #build-tools
        cmake
        gnumake
        gcc
        libtool

        #editorss
        nixfmt-classic
        shfmt
        emacsPackages.treesit-auto
        shellcheck
        graphviz
        nodejs
        python3
        ispell
        sqlite
        nil

        #audio/video
        alsa-utils
        feh
        linux-firmware
        mpv
        pavucontrol
        pipewire
        pulseaudio
        qpwgraph
        vlc
        spotify

        # apps
        appimage-run
        firefox
        google-chrome
        foliate
        remmina
        auth0-cli

        #file manager
        file-roller
        pcmanfm
        p7zip
        rsync
        unzip
        unrar
        wpsoffice
        zip
        maim
        gnuplot
        grip
        usb-modeswitch

        #encryption
        age
        gnupg
        libfido2
        pinentry
        pinentry-curses
        vesktop
        mongodb-compass
        code-cursor
      ] ++ (with stable; [ image-roll ]);
  };

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    nix-ld = {
      enable = true;
      libraries = [ ];
    };
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services = {
    blueman.enable = true;
    pulseaudio.enable = false;
    printing = { enable = true; };
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
    };
    openssh = {
      enable = true;
      allowSFTP = true;
      extraConfig = ''
        HostKeyAlgorithms +ssh-rsa
      '';
    };
  };

  flatpak.enable = true;
  nix = {
    settings = { auto-optimise-store = true; };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 2d";
    };

    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs	    = true
      keep-derivations	    = true
    '';
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.rocmSupport = true;
  system.stateVersion = "25.05";

  home-manager.users.${vars.user} = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
    xdg = {
      mime.enable = true;
      mimeApps = lib.mkIf (config.gnome.enable == false) {
        enable = true;
        defaultApplications = {
          "image/jpeg" = [ "image-roll.desktop" "feh.desktop" ];
          "image/png" = [ "image-roll.desktop" "feh.desktop" ];
          "text/plain" = "emacs.desktop";
          "text/html" = "emacs.desktop";
          "text/csv" = "emacs.desktop";
          "application/pdf" = [
            "wps-office-pdf.desktop"
            "firefox.desktop"
            "google-chrome.desktop"
          ];
          "application/zip" = "org.gnome.FileRoller.desktop";
          "application/x-tar" = "org.gnome.FileRoller.desktop";
          "application/x-bzip2" = "org.gnome.FileRoller.desktop";
          "application/x-gzip" = "org.gnome.FileRoller.desktop";
          "x-scheme-handler/http" =
            [ "firefox.desktop" "google-chrome.desktop" ];
          "x-scheme-handler/https" =
            [ "firefox.desktop" "google-chrome.desktop" ];
          "x-scheme-handler/about" =
            [ "firefox.desktop" "google-chrome.desktop" ];
          "x-scheme-handler/unknown" =
            [ "firefox.desktop" "google-chrome.desktop" ];
          "x-scheme-handler/mailto" = [ "gmail.desktop" ];
          "audio/mp3" = "mpv.desktop";
          "audio/x-matroska" = "mpv.desktop";
          "video/webm" = "mpv.desktop";
          "video/mp4" = "mpv.desktop";
          "video/x-matroska" = "mpv.desktop";
          "inode/directory" = "pcmanfm.desktop";
        };
      };
      desktopEntries.image-roll = {
        name = "image-roll";
        exec = "${stable.image-roll}/bin/image-roll %F";
        mimeType = [ "image/*" ];
      };
      desktopEntries.gmail = {
        name = "Gmail";
        exec = ''xdg-open "https://mail.google.com/mail/?view-cm&fs=1&to=%u"'';
        mimeType = [ "x-scheme-handler/mailto" ];
      };
    };
  };
}
