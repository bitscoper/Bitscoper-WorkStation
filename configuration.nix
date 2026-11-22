# By Abdullah As-Sadeed

{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  ...
}:
let
  stableNixPackages =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-26.05.tar.gz";
      })
      {
        config = config.nixpkgs.config;
      };

  homeManagerFlake = builtins.getFlake "github:nix-community/home-manager/master";
  sysdManagerFlake = builtins.getFlake "github:plrigaux/sysd-manager/main";
  catppuccinThemeFlake = builtins.getFlake "github:catppuccin/nix/main";

  fontPreferences = {
    monospace = "NotoMono Nerd Font Mono";
    sansSerif = "NotoSans Nerd Font";
    serif = "NotoSerif Nerd Font";
    emoji = "Noto Color Emoji";
  };

  bgrtBmpFile = builtins.path {
    path = "/sys/firmware/acpi/bgrt/image";
    name = "bgrt.bmp";
  };
  themedBgrtPngFile =
    pkgs.runCommand "Themed_BGRT.png"
      {
        nativeBuildInputs = with pkgs; [
          imagemagickBig
        ];
      }
      ''
        set -euo pipefail

        magick BMP:${bgrtBmpFile} \
          -fuzz 16% \
          -transparent black \
          -background "#1e1e2e" \
          -resize ${pkgs.lib.toString (config.customOptions.hardwareSpecificConfiguration.screen.width)}x${pkgs.lib.toString (config.customOptions.hardwareSpecificConfiguration.screen.height)}\> \
          -gravity center \
          -extent ${pkgs.lib.toString (config.customOptions.hardwareSpecificConfiguration.screen.width)}x${pkgs.lib.toString (config.customOptions.hardwareSpecificConfiguration.screen.height)} \
          $out
      '';
  # It assumes that the background color of BGRT is black and that 16% fuzz is sufficient.
  # #1e1e2e: Base of Catppuccin Mocha

  wallpaperFile = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/Shavanced/ame-quattro/refs/heads/main/backgrounds/21330483-catppuccin-mocha.png";
  };

  designFactor = 8.0;
  transitionDuration = 400; # 400 Milliseconds

  tlsCertificateFiles =
    pkgs.runCommand "TLS_Certificate_Files"
      {
        CN = config.networking.fqdn;
      }
      ''
        set -euo pipefail

        mkdir -p "$out"

        cat > OpenSSL.cnf <<EOF
        [req]
        prompt = no
        distinguished_name = dn
        x509_extensions = v3_ca

        [dn]
        CN = $CN

        [v3_ca]
        basicConstraints = critical, CA:TRUE
        keyUsage = critical, digitalSignature, keyCertSign, cRLSign
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid:always
        subjectAltName = @alt_names

        [alt_names]
        DNS.1 = $CN
        EOF

        ${pkgs.openssl}/bin/openssl ecparam -name secp521r1 -genkey -noout -out "$out/Private.key"

        ${pkgs.openssl}/bin/openssl req -new -x509 -key "$out/Private.key" -out "$out/Certificate.crt" -days 36500 -config OpenSSL.cnf

        cat "$out/Private.key" "$out/Certificate.crt" > "$out/Concatenated.pem"

        cp "$out/Certificate.crt" "$out/CA_Certificate.crt"
      '';
  tlsCACertificateFile = "${tlsCertificateFiles}/CA_Certificate.crt";
  tlsCertificateFile = "${tlsCertificateFiles}/Certificate.crt";
  tlsCertificatePrivateKeyFile = "${tlsCertificateFiles}/Private.key";
  tlsCertificateConcatenatedFile = "${tlsCertificateFiles}/Concatenated.pem";
in
{
  _class = "nixos";

  _module.args = {
    inherit
      designFactor
      fontPreferences
      themedBgrtPngFile
      tlsCACertificateFile
      tlsCertificateConcatenatedFile
      tlsCertificateFile
      tlsCertificatePrivateKeyFile
      transitionDuration
      wallpaperFile
      ;
  };

  imports = [
    homeManagerFlake.nixosModules.home-manager
    catppuccinThemeFlake.nixosModules.catppuccin

    ./Modules/AppImage.nix
    ./Modules/Avahi.nix
    ./Modules/bat.nix
    ./Modules/BlueZ.nix
    ./Modules/brightnessctl.nix
    ./Modules/Btrfs.nix
    ./Modules/chrony.nix
    ./Modules/Cine.nix
    ./Modules/cliphist.nix
    ./Modules/Cockpit.nix
    ./Modules/Contour.nix
    ./Modules/CPU-X.nix
    ./Modules/Curtail.nix
    ./Modules/D-Bus.nix
    ./Modules/direnv.nix
    ./Modules/Evince.nix
    ./Modules/Exhibit.nix
    ./Modules/Fastfetch.nix
    ./Modules/Fcitx_5.nix
    ./Modules/fdroidcl.nix
    ./Modules/FFmpeg.nix
    ./Modules/Firefox.nix
    ./Modules/Flutter.nix
    ./Modules/fprintd.nix
    ./Modules/fwupd.nix
    ./Modules/Git.nix
    ./Modules/GNOME_Keyring.nix
    ./Modules/GNU_Bash.nix
    ./Modules/GNU_GRand_Unified_Bootloader.nix
    ./Modules/GnuPG.nix
    ./Modules/GPSd.nix
    ./Modules/GStreamer.nix
    ./Modules/GTK.nix
    ./Modules/Hardinfo2.nix
    ./Modules/hypridle.nix
    ./Modules/Hyprland.nix
    ./Modules/hyprlock.nix
    ./Modules/hyprpaper.nix
    ./Modules/Hyprshot.nix
    ./Modules/I2C.nix
    ./Modules/Icecast.nix
    ./Modules/ImHex.nix
    ./Modules/Jellyfin.nix
    ./Modules/KeePassXC.nix
    ./Modules/Kubernetes.nix
    ./Modules/LibreOffice.nix
    ./Modules/libvirt.nix
    ./Modules/Loupe.nix
    ./Modules/Lutris.nix
    ./Modules/MariaDB.nix
    ./Modules/Nautilus.nix
    ./Modules/NetworkManager.nix
    ./Modules/nix-index.nix
    ./Modules/Nocturne.nix
    ./Modules/nwg-bar.nix
    ./Modules/nwg-drawer.nix
    ./Modules/Ollama.nix
    ./Modules/Open_Broadcaster_Software_Studio.nix
    ./Modules/OpenCode.nix
    ./Modules/OpenDM.nix
    ./Modules/OpenSSH.nix
    ./Modules/PeaZip.nix
    ./Modules/PHP.nix
    ./Modules/PipeWire.nix
    ./Modules/Playerctl.nix
    ./Modules/Plymouth.nix
    ./Modules/Podman.nix
    ./Modules/polkit.nix
    ./Modules/PostgreSQL.nix
    ./Modules/qBittorrent.nix
    ./Modules/Qt.nix
    ./Modules/Resources.nix
    ./Modules/Rofi.nix
    ./Modules/rtl-sdr.nix
    ./Modules/Simple_Desktop_Display_Manager.nix
    ./Modules/Starship.nix
    ./Modules/Sudo.nix
    ./Modules/SwayNotificationCenter.nix
    ./Modules/sysctl.nix
    ./Modules/Syshud.nix
    ./Modules/systemd.nix
    ./Modules/Tailscale.nix
    ./Modules/Tor.nix
    ./Modules/udev.nix
    ./Modules/udiskie.nix
    ./Modules/Ungoogled_Chromium.nix
    ./Modules/Universal_Wayland_Session_Manager.nix
    ./Modules/vivid.nix
    ./Modules/Waybar.nix
    ./Modules/Waydroid.nix
    ./Modules/Wayscriber.nix
    ./Modules/WayVNC.nix
    ./Modules/Wireshark.nix
    ./Modules/xdg-desktop-portal-gtk.nix
    ./Modules/XDG.nix
    ./Modules/Zed.nix

    ./Hardware_Specific_Modules/ASUS_VivoBook_X415EA.nix
    ./Hardware_Specific_Modules/Fantech_EOS_Lite_GP15L_Multi-Platform_Gamepad.nix
    ./Hardware_Specific_Modules/SDDPNQD-512G-1102.nix
    ./Hardware_Specific_Modules/WDS1TB2G0A-00.nix

    ./hardware-configuration.nix
  ];

  nix = {
    enable = true;
    package = pkgs.nix;

    channel.enable = true;

    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];

      sandbox = true;
      auto-optimise-store = true;

      trusted-users = [
        "root"
        "@wheel"
      ];

      # substituters = [ ];

      require-sigs = true;
      trusted-substituters = config.nix.settings.substituters;
      # trusted-public-keys = [ ];

      cores = 0; # 0 = All
      max-jobs = 1;
    };

    gc.automatic = !config.programs.nh.enable;

    optimise = {
      automatic = true;

      dates = "weekly";
      persistent = true;
    };

    daemonCPUSchedPolicy = "batch";
    daemonIOSchedClass = "best-effort";

    firewall.enable = false;

    checkConfig = true;
    checkAllErrors = true;
  };

  nixpkgs = {
    config = {
      allowAliases = false;
      allowUnfree = true;

      permittedInsecurePackages = pkgs.lib.optionals config.nixpkgs.config.allowUnfree [
        "ventoy-1.1.18"
      ];
    };

    overlays = [
      (final: previous: {
        coreutils-full = previous.coreutils-full.override {
          aclSupport = true;
          withOpenssl = true;
        };
      })
    ];
  };

  appstream.enable = true;

  system = {
    copySystemConfiguration = true;

    switch.enable = true;
    tools = {
      nixos-build-vms.enable = true;
      nixos-enter.enable = true;
      nixos-generate-config.enable = true;
      nixos-install.enable = true;
      nixos-option.enable = true;
      nixos-rebuild.enable = true;
      nixos-version.enable = true;
    };

    activationScripts = {
      linkLocales = ''
        set -euo pipefail

        mkdir --parents /usr/share/i18n
        ln --symbolic --force --no-dereference /run/current-system/sw/share/i18n/locales /usr/share/i18n/locales
      '';
    };

    # userActivationScripts = { };

    stateVersion = "26.11";
  };

  boot = {
    kernel = {
      enable = true;
    };

    kernelPackages = pkgs.linuxPackages_zen;

    extraModulePackages = with config.boot.kernelPackages; [
      # openafs # FIXME: Build Failure
      # zfs_2_4 # Marked as Broken
      apfs
      bcachefs
      cpupower
      mm-tools
      systemd
      tmon
      turbostat
    ];

    hardwareScan = true;

    kernelModules = [
      "at24" # SDR/DDR/DDR2/DDR3 SPD and I²C
      "ee1004" # DDR4 SPD
      "spd5118" # DDR5 SPD
    ];

    blacklistedKernelModules = [
      "efifb"
      "simplefb"
    ];

    kernelParams = [
      "boot.shell_on_fail"
      "initcall_blacklist=simpledrm_platform_driver_init"
      "iommu=pt"
      "mitigations=auto"
      "splash"
    ];

    initrd = {
      enable = true;

      kernelModules = config.boot.kernelModules;
      availableKernelModules = [
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      network.enable = true;
    };

    tmp = {
      cleanOnBoot = true;
    };

    kexec.enable = true;

    consoleLogLevel = 4; # 4 = KERN_WARNING
  };

  powerManagement = {
    enable = true;

    scsiLinkPolicy = "max_performance";

    # powerUpCommands = '''';
    # bootCommands = '''';
    # resumeCommands = '''';
    # powerDownCommands = '''';
  };

  hardware = {
    enableAllFirmware = config.nixpkgs.config.allowUnfree;
    enableRedistributableFirmware = true;
    firmware = with pkgs; [
      linux-firmware
    ];

    firmwareCompression = "zstd";

    block = {
      scheduler = {
        "mmcblk[0-9]*" = "bfq";
        "nvme[0-9]*" = "none";
      };

      defaultScheduler = "none";
      defaultSchedulerExclude = "loop[0-9]*";
      defaultSchedulerRotational = "bfq";
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  systemd.tmpfiles.rules = [
    "L+ /lib/modules/ - - - - /run/current-system/kernel-modules/lib/modules/"
  ];

  security = {
    allowSimultaneousMultithreading = true;
    forcePageTableIsolation = true;

    tpm2.enable = true;

    lockKernelModules = false;

    rtkit.enable = true;

    pam = {
      mount = {
        enable = true;

        createMountPoints = true;
        removeCreatedMountPoints = true;

        logoutHup = true;
        logoutTerm = false;
        logoutKill = false;

        logoutWait = 0;
      };

      services = builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value = {
              unixAuth = true;
              fprintAuth = true;

              rules.auth = {
                unix = {
                  modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
                  control = "sufficient";
                  order = 1;
                };

                fprintd = {
                  modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
                  control = "sufficient";
                  order = 2;
                };
              };

              allowNullPassword = pkgs.lib.mkForce false;
              logFailures = true;
              nodelay = false;

              enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;

              gnupg = {
                enable = config.home-manager.users.normal.programs.gpg.enable;
                storeOnly = false;
                noAutostart = false;
              };

              showMotd = true;
            };
          })
          [
            "login"
            "su"
            "vlock"
          ]
      ); # ls /etc/pam.d/
    };

    enableWrappers = true;

    audit = {
      enable = true;
      package = (
        pkgs.audit.override {
          enablePython = true;
        }
      );

      failureMode = "printk";
      rateLimit = 0; # 0 = Unlimited
    };

    auditd = {
      enable = true;
      package = config.security.audit.package;
    };
  };

  networking = {
    enableIPv6 = true;

    domain = "local";
    hostName = "bitscoper-workstation";
    fqdn = "${config.networking.hostName}.${config.networking.domain}";

    wireless = {
      dbusControlled = config.services.dbus.enable;
      userControlled = true;
      enableHardening = true;
    };

    useDHCP = if config.networking.networkmanager.dhcp == "internal" then false else true;
    dhcpcd.enable = false;

    firewall = {
      enable = true;

      allowPing = true;

      # allowedTCPPorts = [
      # ];

      # allowedUDPPorts = [
      # ];
    };
  };

  i18n = {
    defaultCharset = "UTF-8";

    localeCharsets = {
      LC_ADDRESS = config.i18n.defaultCharset;
      LC_COLLATE = config.i18n.defaultCharset;
      LC_CTYPE = config.i18n.defaultCharset;
      LC_IDENTIFICATION = config.i18n.defaultCharset;
      LC_MEASUREMENT = config.i18n.defaultCharset;
      LC_MESSAGES = config.i18n.defaultCharset;
      LC_MONETARY = config.i18n.defaultCharset;
      LC_NAME = config.i18n.defaultCharset;
      LC_NUMERIC = config.i18n.defaultCharset;
      LC_PAPER = config.i18n.defaultCharset;
      LC_TELEPHONE = config.i18n.defaultCharset;
      LC_TIME = config.i18n.defaultCharset;

      LC_ALL = config.i18n.defaultCharset;
    };

    defaultLocale = "en_US.UTF-8";
    extraLocales = "all";

    extraLocaleSettings = {
      LC_ADDRESS = config.i18n.defaultLocale;
      LC_COLLATE = config.i18n.defaultLocale;
      LC_CTYPE = config.i18n.defaultLocale;
      LC_IDENTIFICATION = config.i18n.defaultLocale;
      LC_MEASUREMENT = config.i18n.defaultLocale;
      LC_MESSAGES = config.i18n.defaultLocale;
      LC_MONETARY = config.i18n.defaultLocale;
      LC_NAME = config.i18n.defaultLocale;
      LC_NUMERIC = config.i18n.defaultLocale;
      LC_PAPER = config.i18n.defaultLocale;
      LC_TELEPHONE = config.i18n.defaultLocale;
      LC_TIME = config.i18n.defaultLocale;

      LC_ALL = config.i18n.defaultLocale;
    };
  };

  services = {
    das_watchdog.enable = true;

    fstrim = {
      enable = true;
      interval = "weekly";
    };

    upower = {
      enable = true;
      package = (
        pkgs.upower.override {
          withDocs = true;
          withIntrospection = true;

        }
      );

      allowRiskyCriticalPowerAction = false;
      criticalPowerAction = "PowerOff";

      ignoreLid = true;
    };

    acpid = {
      enable = true;

      # powerEventCommands = '''';
      # acEventCommands = '''';
      # lidEventCommands = '''';

      logEvents = false;
    };

    thermald = {
      enable = true;
      package = pkgs.thermald;

      ignoreCpuidCheck = false;

      debug = config.environment.enableDebugInfo;
    };

    colord.enable = true;

    smartd = {
      enable = true;

      autodetect = true;

      notifications = {
        mail.enable = false;
        systembus-notify.enable = false;
        test = false;
        wall.enable = true;
      };
    };

    udisks2 = {
      enable = true;
      package = pkgs.udisks;

      mountOnMedia = false;
    };

    accounts-daemon.enable = true;

    gvfs = {
      enable = true;
      package = (
        pkgs.gvfs.override {
          gnomeSupport = false;
          udevSupport = config.services.udev.enable;
        }
      );
    };

    sysstat = {
      enable = true;
    };

    logrotate = {
      enable = true;

      allowNetworking = true;
      checkConfig = true;
    };
  };

  programs = {
    nix-ld = {
      enable = true;
      package = pkgs.nix-ld;

      libraries =
        options.programs.nix-ld.libraries.default
        ++ (with pkgs; [
          glib.out
          llvmPackages.stdenv.cc.cc.lib
          sqlite
          stdenv.cc
          stdenv.cc.cc.lib
        ]);
    };

    nh = {
      enable = true;
      package = pkgs.nh;

      clean = {
        enable = true;

        dates = "weekly";
        extraArgs = "--optimise";
      };
    };

    command-not-found.enable = true;

    usbtop.enable = true;

    nano.enable = false;

    dconf = {
      enable = true;

      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "org/gnome/desktop/privacy" = {
              remember-recent-files = false;
            };
          };
        }
      ];
    };

    partition-manager = {
      enable = true;
    };

    k3b.enable = true;

    localsend = {
      enable = true;
      package = pkgs.localsend;

      openFirewall = true;
    };
  };

  fonts = {
    enableDefaultPackages = false;
    enableGhostscriptFonts = false;
    packages =
      with pkgs;
      [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-lgc-plus
      ]
      ++ [
        config.home-manager.users.normal.gtk.font.package
      ]
      ++ pkgs.lib.optionals config.nixpkgs.config.allowUnfree (
        with pkgs;
        [
          corefonts
        ]
      );

    fontconfig = {
      enable = true;

      allowBitmaps = true;
      allowType1 = false;
      cache32Bit = true;

      defaultFonts = {
        monospace = [
          fontPreferences.monospace
        ];

        sansSerif = [
          fontPreferences.sansSerif
        ];

        serif = [
          fontPreferences.serif
        ];

        emoji = [
          fontPreferences.emoji
        ];
      };

      useEmbeddedBitmaps = false;
      antialias = true;

      hinting = {
        enable = true;

        autohint = false;
        style = "full";
      };

      subpixel = {
        rgba = "rgb";
        lcdfilter = "default";
      };

      includeUserConf = true;
    };
  };

  environment = {
    enableAllTerminfo = true;

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    systemPackages =
      with pkgs;
      [
        # apkeep # FIXME: Build Failure
        # darling-dmg # Marked as Broken
        # flake-checker # FIXME: Build Failure
        # genealogos-cli # FIXME: Build Failure
        # markitdown # FIXME: Build Failure
        # newsflash # FIXME: Build Failure
        # oha # FIXME: Build Failure
        # python314Packages.pymobiledevice3 # Marked as Broken
        # reiser4progs # Marked as Broken
        # soundconverter # FIXME: Build Failure
        # streamlit # FIXME: Build Failure
        # video2x # FIXME: Build Failure
        # zizmor # FIXME: Build Failure
        aapt
        acl
        acpica-tools
        acpidump-all
        act
        actionlint
        addlicense
        aegisub
        aide
        aircrack-ng
        android-backup-extractor
        angryipscanner
        ansilove
        apfs-fuse
        apfsprogs
        apkleaks
        archivemount
        arduino-cli
        arduino-core
        arduino-ide
        arduino-ota
        arj
        ascii-draw
        asciinema
        asciinema-agg
        asciiquarium-transparent
        asnmap
        audio-sharing
        avbroot
        avrdude
        backgroundremover
        bada-bib
        bcachefs-tools
        binary
        bindfs
        blanket
        bleachbit
        btfs
        bzip3
        calligraphy
        cartero
        cavasik
        celt
        censor
        certbot-full
        certdump
        chunkfs
        clapgrep
        clinfo
        cloc
        cloneit
        cloudflared
        codeowners
        codevis
        colorgrind
        compose2nix
        compsize
        concessio
        constrict
        coreutils-full
        coulomb
        cpio
        cramfsprogs
        crlfuzz
        crow-translate
        cryptsetup
        cve-bin-tool
        cyclonedx-cli
        cyclonedx-python
        daemon
        darktable
        davfs2
        dbeaver-bin # To Use the GTK Theme: Window > Preferences > "User Interface" > Appearance > Uncheck "Enable theming"
        dconf-editor
        dconf2nix
        ddrescue
        ddrescueview
        dduper
        delineate
        desktop-file-utils
        dig
        dippi
        dislocker
        disorderfs
        dmg2img
        dmidecode
        dnsrecon
        door-knocker
        dosfstools
        dot2tex
        dvb-apps
        e2fsprogs
        efibootmgr
        efivar
        egypt
        elf-dissector
        eloquent
        emblem
        envfs
        erofs-utils
        esptool
        etherape
        exfatprogs
        exiftool
        extract-dtb
        f2fs-tools
        fastlane
        fdk_aac
        fdt-viewer
        fdupes
        ffmpegthumbnailer
        fh
        file
        fileinfo
        findutils
        flare-floss
        flawz
        flightgear
        font-manager
        fontfor
        freerouting
        fritzing
        fuse-overlayfs
        fuse3
        gawd
        gawk
        gcc
        gcr_4
        gdk-pixbuf
        gerbolyze
        gh
        gh-contribs
        gh-skyline
        gh2md
        ghatm
        ghrepo-stats
        gimp-with-plugins
        github-backup
        github-changelog-generator
        github-distributed-owners
        glab
        glib
        glib-networking
        glibc
        gnome-characters
        gnome-frog
        gnome-multi-writer
        gnucash
        gnugrep
        gnumake
        gnused
        gnutar
        go-mtpfs
        go2tv
        goldendict-ng
        google-lighthouse
        gphoto2fs
        gpu-viewer
        graphviz
        gtk-frdp
        gtkhash
        gucharmap
        gzip
        halftone
        hashes
        hdparm
        heaptrack
        hfsprogs
        hfsutils
        hieroglyphic
        horizon-eda
        hstsparser
        httpdirfs
        hw-probe
        hydra-check
        hyprmag
        hyprshutdown
        hyprtoolkit
        ifuse
        imagemagickBig
        inetutils
        inkscape-with-extensions
        inotify-tools
        interception-tools
        iplookup-gtk
        jfsutils
        jmol
        jq
        jxrlib
        karlender
        kdiff3
        kernel-hardening-checker
        kernelshark
        kexec-tools
        kmod
        kotlin
        krapslog
        krename
        krita
        krita-plugin-gmic
        kronometer
        labplot
        lenspect
        letterpress
        lha
        libaom
        libavif
        libde265
        libfreeaptx
        libheif.bin
        libheif.out
        libilbc
        libimobiledevice
        libjxl
        liblc3
        libnotify
        libogg
        libopus
        libsixel
        libultrahdr
        libva-utils
        libvpx
        linux-exploit-suggester
        livecaptions
        llmfit
        logtop
        lorem
        lsb-release
        lsof
        lsscsi
        luminance
        lvm2
        lynis
        lyto
        lyx
        lzham
        macchanger
        mailcap
        mergerfs
        mesa-demos
        metadata-cleaner
        metronome
        mfcuk
        mfoc
        monkeys-audio
        morphosis
        mousam
        mp3fs
        mtools
        mtr-gui # mtr --gtk
        nethogs
        nilfs-utils
        nix-diff
        nix-forecast
        nix-health
        nix-info
        nix-query-tree-viewer
        nixoscope
        nixpkgs-reviewFull
        noaa-apt
        normcap
        ntfs2btrfs
        ntfs3g
        ntfsprogs-plus
        nurl
        nvme-cli
        openafs
        openai-whisper
        openapv
        opencore-amr
        openh264
        openjpeg
        openssl
        otree
        packet
        paleta
        pana
        paper-clip
        parallel-full
        pbzx
        pciutils
        pdfarranger
        pev
        picard
        picard-tools
        platformio
        play
        poop # POOP = Performance Optimizer Observation Platform
        powershell
        procps
        profile-cleaner
        progress
        protocol
        proton-vpn
        psmisc
        qalculate-gtk
        qdirstat
        qr-backup
        qsstv
        qtrvsim
        raider
        rdap
        rp-pppoe
        rpi-imager
        rpmextract
        rt-tests
        runme
        sbc
        sbom2dot
        sbomnix
        schroedinger
        scorecard
        seer # seergdb
        selectdefaultapplication
        semver-tool
        share-preview
        sherlock
        sleuthkit
        smag
        sof-tools
        songrec
        spectre-meltdown-checker
        speedtest
        spytrap-adb
        sqlite-analyzer
        squashfuse
        srain
        sslscan
        stableNixPackages.filen-desktop
        stdenv.cc.libc.out # Includes Locales
        steam-run-free
        stellarium
        strace
        strace-analyzer
        subfinder
        svt-av1
        switcheroo
        syft
        symlinks
        sysdManagerFlake.packages.${config.nixpkgs.hostPlatform.system}.sysd-manager
        tauno-monitor
        telegraph
        teleprompter
        terminaltexteffects
        texliveFull
        time
        tpm2-tools
        traitor
        tree
        treegen
        trueseeing
        trufflehog
        tsukae
        turnon
        udftools
        unarc
        undollar
        unhide-gui
        universal-android-debloater # uad-ng
        unix-privesc-check
        unzip
        updog
        upnp-router-control
        upscayl
        usbutils
        util-linux
        valgrind
        valuta
        vorbis-tools
        vulnix
        wafw00f
        wayback-machine-archiver
        wayback_machine_downloader
        waycheck
        wayland-utils
        webfont-bundler
        webp-pixbuf-loader
        websocat
        wev
        whatfiles
        which
        whois
        wildcard
        windowtolayer
        wvkbd # wvkbd-mobintl
        xar
        xeol
        xfsdump
        xfsprogs
        xfstests
        xoscope
        xvidcore
        xz
        yuview
        zenmap
        zfs
        zip

        # (cutter.withPlugins (plugins: [
        #   plugins.rz-ghidra
        # ])) # FIXME: Build Failure

        (curlFull.override {
          brotliSupport = true;
          c-aresSupport = true;
          gnutlsSupport = false;
          gsaslSupport = true;
          gssSupport = true;
          http2Support = true;
          http3Support = true;
          httpsigSupport = true;
          idnSupport = true;
          ldapSupport = true;
          opensslSupport = true;
          pslSupport = true;
          rustlsSupport = false;
          scpSupport = true;
          websocketSupport = true;
          zlibSupport = true;
          zstdSupport = true;
        })

        (guvcview.override {
          pulseaudioSupport = config.services.pipewire.pulse.enable;
          useGtk = true;
          useQt = false;
        })

        (nwg-displays.override {
          hyprlandSupport = config.programs.hyprland.enable;
        })

        (p7zip.override {
          enableUnfree = config.nixpkgs.config.allowUnfree; # Includes RAR
        })

        (parabolic.override {
          yt-dlp = config.home-manager.users.normal.programs.yt-dlp.package;
        })

        (python315FreeThreading.override {
          bluezSupport = config.hardware.bluetooth.enable;
          enableNoSemanticInterposition = true;
          enableOptimizations = true;
          mimetypesSupport = true;
          withExpat = true;
          withGdbm = true;
          withMpdecimal = true;
          withOpenssl = true;
          withReadline = true;
          withSqlite = true;
        })

        (testdisk-qt.override {
          enableExtFs = true;
          enableNtfs = true;
        }) # qphotorec

        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })

        (zint-qt.override {
          withGUI = true;
        })
      ]

      ++ (with pkgs.kdePackages; [
        kalgebra
        kalzium
        kcachegrind
        kcolorchooser
        kdenlive
        kmahjongg
        kmouth
        kontrast
        kshisen
        ktimer
        kwave
      ])

      ++ (with pkgs.linphonePackages; [
        bc-decaf
        bc-ispell
        bc-soci
        bc-zxing-cpp
        bctoolbox
        bcunit
        belcard
        belle-sip
        belr
        bzrtp
        liblinphone
        lime
        linphone-desktop
        mediastreamer2
        msopenh264
        ortp
      ])

      ++ (with pkgs.unixtools; [
        arp
        column
        fdisk
        fsck
        getopt
        ifconfig
        net-tools
        ping
        procps
        script
        util-linux
        wall
        watch
        whereis
        write
        xxd
      ])

      ++ [
        config.hardware.firmware
      ]

      ++ config.boot.extraModulePackages
      ++ config.fonts.packages
      ++ config.hardware.graphics.extraPackages
      ++ config.hardware.graphics.extraPackages32
      ++ config.programs.nix-ld.libraries

      ++ pkgs.lib.optionals config.nixpkgs.config.allowUnfree (
        with pkgs;
        [
          megasync # Open Source
          rar
          unrar

          (ventoy-full.override {
            withCryptsetup = true;
            withExt4 = true;
            withNtfs = true;
            withXfs = true;
          })
        ]
      );

    pathsToLink = [
      "/share/applications"
      "/share/i18n"
      "/share/thumbnailers"
    ];

    variables = {
      GI_TYPELIB_PATH = pkgs.lib.mkForce "${pkgs.libportal}/lib/girepository-1.0:${pkgs.libportal-gtk4}/lib/girepository-1.0:GI_TYPELIB_PATH";
    };

    sessionVariables = {
      EGL_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland";
      NIXOS_OZONE_WL = 1;
      ANKI_WAYLAND = 1;
      _JAVA_AWT_WM_NONREPARENTING = "1";

      XCURSOR_THEME = config.home-manager.users.normal.home.pointerCursor.name;
      XCURSOR_SIZE = config.home-manager.users.normal.home.pointerCursor.size;
    };

    shellAliases = {
      unbind_i8042_driver = "echo -n i8042 | sudo tee /sys/bus/platform/drivers/i8042/unbind >/dev/null";
      bind_i8042_driver = "echo -n i8042 | sudo tee /sys/bus/platform/drivers/i8042/bind >/dev/null";

      clean_optimise_upgrade = "sudo nh clean all && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
      clean_repair_optimise_upgrade = "sudo nh clean all && sudo nix-store --verify --check-contents --repair && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
    };

    # extraInit = '''';
    # loginShellInit = '''';
    # shellInit = '''';
    # interactiveShellInit = '''';

    enableDebugInfo = false;
  };

  xdg.mime.defaultApplications = {
    "application/vnd.ms-opentype" = "com.github.FontManager.FontViewer.desktop";
    "application/x-font-otf" = "com.github.FontManager.FontViewer.desktop";
    "application/x-font-ttf" = "com.github.FontManager.FontViewer.desktop";
    "font/collection" = "com.github.FontManager.FontViewer.desktop";
    "font/otf" = "com.github.FontManager.FontViewer.desktop";
    "font/sfnt" = "com.github.FontManager.FontViewer.desktop";
    "font/ttc" = "com.github.FontManager.FontViewer.desktop";
    "font/ttf" = "com.github.FontManager.FontViewer.desktop";
    "font/woff" = "com.github.FontManager.FontViewer.desktop";
    "font/woff2" = "com.github.FontManager.FontViewer.desktop";
  };

  catppuccin = {
    enable = true;

    enableReleaseCheck = true;
    cache.enable = true;

    autoEnable = true;
    flavor = "mocha";
    accent = "lavender";

    tty = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
    };

    cursors = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;
    };
  }; # From catppuccinThemeFlake

  documentation = {
    enable = true;

    dev.enable = true;
    doc.enable = true;
    info.enable = true;

    man = {
      enable = true;

      man-db = {
        enable = true;
        package = pkgs.man-db;
      };

      cache = {
        enable = true;
        generateAtRuntime = true;
      }; # Spams "gzip: stdout: Broken pipe"
    };

    nixos = {
      enable = true;

      includeAllModules = true;
      checkRedirects = true;

      options.warningsAreErrors = false;
    };
  };

  users = {
    enforceIdUniqueness = true;
    mutableUsers = true;
    manageLingering = true;

    motd = "Welcome to ${config.networking.fqdn}";

    users = {
      root = {
        enable = true;

        isSystemUser = true;
        isNormalUser = false;

        createHome = true;
        homeMode = "700";

        linger = true;
      };

      normal = {
        enable = true;

        isSystemUser = false;
        isNormalUser = true;

        createHome = true;
        homeMode = "700";

        uid = 1000;
        name = "normal";
        description = "Abdullah As-Sadeed"; # Full Name

        extraGroups = [
          "adm"
          "cdrom"
          "dialout"
          "disk"
          "input"
          "lp"
          "plugdev"
          "render"
          "tty"
          "users"
          "uucp"
          "video"
          "wheel"
        ];

        linger = true;

        useDefaultShell = true;
      };
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "bak";

    sharedModules = [
      catppuccinThemeFlake.homeModules.catppuccin

      {
        _class = "homeManager";

        home = {
          enableNixpkgsReleaseCheck = true;

          shell = {
            enableShellIntegration = true;
            enableBashIntegration = true;
          };

          pointerCursor = {
            enable = true;

            name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
            # package = config.catppuccin.sources.cursors."${config.catppuccin.flavor}${pkgs.lib.toSentenceCase config.catppuccin.accent}"; # Already Defined by Catppuccin
            size = builtins.floor (designFactor * 3.0);

            gtk = {
              enable = true;
              size = config.home-manager.users.normal.home.pointerCursor.size;
            };

            x11.enable = config.programs.hyprland.xwayland.enable;

            dotIcons.enable = true;
          };

          # sessionSearchVariables = { };

          # activation = { };

          enableDebugInfo = config.environment.enableDebugInfo;

          stateVersion = config.system.stateVersion;
        };

        fonts.fontconfig = {
          enable = config.fonts.fontconfig.enable;

          defaultFonts = config.fonts.fontconfig.defaultFonts;

          antialiasing = config.fonts.fontconfig.antialias;
          hinting = pkgs.lib.optionals config.fonts.fontconfig.hinting.enable config.fonts.fontconfig.hinting.style;
          subpixelRendering = config.fonts.fontconfig.subpixel.rgba;
        };

        services = {
          poweralertd.enable = true;
        };

        programs = {
          command-not-found.enable = config.programs.command-not-found.enable;

          mcp = {
            enable = true;

            servers = {
              codebase-memory-mcp = {
                enabled = true;

                command = "${pkgs.codebase-memory-mcp}/bin/codebase-memory-mcp";
              };

              context-mode = {
                enabled = true;

                command = "${pkgs.context-mode}/bin/context-mode";
              };

              crw-mcp = {
                enabled = true;

                command = "${pkgs.fastcrw}/bin/crw-mcp";
              };

              # markitdown-mcp = {
              #   enabled = true;

              #   command = "${pkgs.markitdown-mcp}/bin/markitdown-mcp";
              # }; # FIXME: Build Failure

              mcp-nixos = {
                enabled = true;

                command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
              };

              mcp-server-fetch = {
                enabled = true;

                command = "${pkgs.mcp-server-fetch}/bin/mcp-server-fetch";
              };

              mcp-server-sequential-thinking = {
                enabled = true;

                command = "${pkgs.mcp-server-sequential-thinking}/bin/mcp-server-sequential-thinking";
              };

              open-websearch = {
                enabled = true;

                command = "${pkgs.open-websearch}/bin/open-websearch";
                env = {
                  MODE = "stdio";
                  DEFAULT_SEARCH_ENGINE = "duckduckgo";
                };
              };
            };
          };

          matplotlib = {
            enable = true;

            config = {
              axes = {
                grid = true;
              };
            };
          };

          yt-dlp = {
            enable = true;
            package = (
              pkgs.yt-dlp.override {
                atomicparsleySupport = true;
                ffmpegSupport = true;
                rtmpSupport = true;
                withAlias = true;
              }
            );

            settings = {
              no-embed-thumbnail = true;
            };
          };

          man = {
            enable = config.documentation.man.enable;
            package = config.documentation.man.man-db.package;
            man-db.enable = config.documentation.man.man-db.enable;

            generateCaches = config.documentation.man.cache.enable;
          };

          info = {
            enable = config.documentation.info.enable;
            package = pkgs.texinfoInteractive;
          };
        };

        catppuccin = {
          enable = config.catppuccin.enable;

          enableReleaseCheck = config.catppuccin.enableReleaseCheck;
          cache.enable = config.catppuccin.cache.enable;

          autoEnable = config.catppuccin.autoEnable;
          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;

          cursors = {
            enable = config.catppuccin.cursors.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          hyprtoolkit = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };
        }; # From catppuccinThemeFlake

        manual = {
          manpages.enable = true;
          html.enable = true;
          json.enable = false; # Not Needed
        };
      }
    ];

    users = {
      root = { };
      normal = { };
    };

    verbose = true;
  }; # From homeManagerFlake
}
