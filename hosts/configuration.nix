{
  lib,
  config,
  pkgs,
  stable,
  inputs,
  vars,
  ...
}:
let
  terminal = pkgs.${vars.terminal};
in
{
  imports = (
    import ../modules/home
    ++ import ../modules/desktops
    ++ import ../modules/programs
    ++ import ../modules/services
    ++ import ../modules/shell
    ++ import ../modules/editors
    ++ import ../modules/theming
  );

  boot = {
    tmp = {
      cleanOnBoot = true;
      tmpfsSize = "5GB";
    };
  };

  users.users.${vars.user} = {
    isNormalUser = true;
    home = "/home/${vars.user}";
    extraGroups = [
      "wheel"
      "video"
      "audio"
      "camera"
      "networkmanager"
      "lp"
      "scanner"
      "adbusers"
    ];
    linger = true;
  };
  security.chromiumSuidSandbox.enable = true;

  time.timeZone = "Europe/Oslo";
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = true;
    pki.certificates = [
      ''
        -----BEGIN CERTIFICATE-----
        MIICEjCCAbmgAwIBAgIUCwJufhGCR9vskIj786aC1kr6MmgwCgYIKoZIzj0EAwIw
        XzELMAkGA1UEBhMCTk8xDTALBgNVBAgMBE9zbG8xDTALBgNVBAcMBE9zbG8xFTAT
        BgNVBAoMDGRldnJhbmRvbS5jbzEbMBkGA1UEAwwSSm9lbCBKZXJvbWUgRFNvdXph
        MB4XDTI1MTEyNjEyMDUwM1oXDTM1MTEyNDEyMDUwM1owXzELMAkGA1UEBhMCTk8x
        DTALBgNVBAgMBE9zbG8xDTALBgNVBAcMBE9zbG8xFTATBgNVBAoMDGRldnJhbmRv
        bS5jbzEbMBkGA1UEAwwSSm9lbCBKZXJvbWUgRFNvdXphMFkwEwYHKoZIzj0CAQYI
        KoZIzj0DAQcDQgAEs85bPQY+6CS10BJR8CsUmzx0UPrC1/P66mm5w/2cpkiEwbol
        bw8Jr1D575GSgz3QfZVOkr/B6Bjc58N9DK8UiaNTMFEwHQYDVR0OBBYEFFkeBcPT
        169ewp12sWK+VI6ZCW+IMB8GA1UdIwQYMBaAFFkeBcPT169ewp12sWK+VI6ZCW+I
        MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDRwAwRAIgK7KlSmRZvtcUaie8
        D/hSdlgUk6zRf1bhhjUV7IhdhNkCIBB3yUQVjKXApXTCe5dTmq8GJnMFE0OgSMP9
        +qoUuFSO
        -----END CERTIFICATE-----
      ''
    ];
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
    noto-fonts-color-emoji
    # (nerdfonts.override { fonts = [ "FiraCode" ]; })
    nerd-fonts.fira-code
  ];

  # services.udev.packages = [ pkgs.android-udev-rules ];

  environment = {
    variables = {
      TERMINAL = "${vars.terminal}";
      EDITOR = "${vars.editor}";
      VISUAL = "${vars.editor}";
      # VA-API / VDPAU (NVIDIA) — merged here to keep one environment.variables.
      VDPAU_DRIVER = "va_gl";
      LIBVA_DRIVER_NAME = "nvidia";
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
    systemPackages =
      with pkgs;
      [
        # terminal
        terminal
        tmux
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
        nixfmt
        shfmt
        emacsPackages.treesit-auto
        shellcheck
        graphviz
        python3
        ispell
        nchat
        sqlite
        nil
        claude-code # Claude Code CLI (nixpkgs) — declarative, no imperative install

        #audio/video
        alsa-utils
        feh
        linux-firmware
        pavucontrol
        pipewire
        pulseaudio
        qpwgraph

        # apps
        appimage-run
        firefox
        google-chrome
        foliate
        remmina

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
        expressvpn
        newsflash

        #encryption
        age
        libfido2

        #android
        android-tools

        # figma
        figma-linux
        uv
      ]
      ++ (with stable; [ image-roll ]);
  };

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
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
    printing = {
      enable = true;
    };
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

  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    age.keyFile = "/home/joel/.config/sops/age/keys.txt";

    secrets = {
      "ca_key" = { };
      emacs_authinfo = {
        path = "/home/joel/.authinfo";
        owner = "joel";
        format = "yaml";
      };

      "upstash_api_key" = {
        owner = "joel";
      };
    };
  };

  ## Custom CA

  ## Networking and DNS
  networking = {
    networkmanager.enable = true;
    useDHCP = lib.mkDefault true;
    firewall.allowedTCPPorts = [ 57621 ];
    firewall.allowedUDPPorts = [ 5353 ];
    firewall.trustedInterfaces = [ "virbr1" ];
  };

  networking.networkmanager.dns = "none";
  networking.nameservers = [
    "127.0.0.1"
    "::1"
  ];

  services.dnsmasq = {
    enable = true;
    settings = {
      server = [
        "1.1.1.1"
        "8.8.8.8"
      ];
      domain-needed = true;
      bogus-priv = true;
      no-resolv = true;
      address = [
        "/trive.ai/127.0.0.1"
        "/trive.ai/::1"
        "/vm.trive.ai/192.168.123.100"
      ];
      interface = "lo";
      bind-interfaces = true;
    };
  };
  services.resolved.enable = false;
  services.nginx = {
    enable = true;
    streamConfig = ''
      upstream trive_backend {
         server 192.168.123.100:443 max_fails=1 fail_timeout=5s;
         server trive.ai:443 backup;
      }

      server {
        listen 127.0.0.1:443;
        listen [::1]:443;
        proxy_pass trive_backend;
        ssl_preread on;
        resolver 8.8.8.8;
      }

      server {
          listen 127.0.0.1:80;
          proxy_pass trive_backend; 
      }
    '';
  };

  flatpak.enable = true;
  nix = {
    settings = {
      auto-optimise-store = true;

      # ── Build parallelism ──────────────────────────────────────────────
      # max-jobs=auto → one build job per core; cores=0 → each job uses all
      # cores. Saturates the desktop CPU during rebuilds.
      max-jobs = "auto";
      cores = 0;

      # ── Binary caches ──────────────────────────────────────────────────
      # The big win: pull Hyprland (and nix-community builds) as prebuilt
      # binaries instead of compiling from source on every input bump.
      builders-use-substitutes = true;
      substituters = [
        "https://cache.nixos.org"
        "https://hyprland.cachix.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
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

  home-manager.backupFileExtension = "bak";

  home-manager.users.${vars.user} = {
    home.stateVersion = "25.05";
    programs.home-manager.enable = true;
    xdg = {
      mime.enable = true;
      mimeApps = {
        enable = true;
        defaultApplications = {
          "image/jpeg" = [
            "image-roll.desktop"
            "feh.desktop"
          ];
          "image/png" = [
            "image-roll.desktop"
            "feh.desktop"
          ];
          "text/plain" = "emacs.desktop";
          "text/html" = "google-chrome.desktop";
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
          "x-scheme-handler/http" = [
            "firefox.desktop"
            "google-chrome.desktop"
          ];
          "x-scheme-handler/https" = [
            "firefox.desktop"
            "google-chrome.desktop"
          ];
          "x-scheme-handler/about" = [
            "firefox.desktop"
            "google-chrome.desktop"
          ];
          "x-scheme-handler/unknown" = [
            "firefox.desktop"
            "google-chrome.desktop"
          ];
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
