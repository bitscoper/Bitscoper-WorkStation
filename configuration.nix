# By Abdullah As-Sadeed

{
  config,
  options,
  pkgs,
  lib,
  ...
}:
let
  # stable = import (builtins.fetchTarball {
  #   url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-25.11.tar.gz";
  # }) { };

  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/refs/heads/master.tar.gz";

  dankmaterialshellPluginRegistryFlake = builtins.getFlake "github:AvengeMedia/dms-plugin-registry";

  quickshellFlake = builtins.getFlake "git+https://git.outfoxxed.me/quickshell/quickshell";

  android_nixpkgs =
    pkgs.callPackage
      (import (
        builtins.fetchGit {
          url = "https://github.com/tadfisher/android-nixpkgs.git";
        }
      ))
      {
        channel = "canary";
      };
  android_sdk = android_nixpkgs.sdk (
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-0
      build-tools-36-1-0
      cmake-3-22-1
      cmake-4-1-2
      cmdline-tools-latest
      emulator
      ndk-28-2-13676358
      ndk-29-0-14206865
      platform-tools
      platforms-android-28
      platforms-android-29
      platforms-android-30
      platforms-android-31
      platforms-android-32
      platforms-android-33
      platforms-android-34
      platforms-android-35
      platforms-android-36
      platforms-android-36-1
      system-images-android-36-1-google-apis-playstore-x86-64
      tools
    ] # https://github.com/tadfisher/android-nixpkgs/tree/main/channels/
  );
  android_sdk_path = "${android_sdk}/share/android-sdk";

  font_preferences = {
    package = pkgs.nerd-fonts.noto;

    name = {
      mono = "NotoMono Nerd Font Mono";
      sans_serif = "NotoSans Nerd Font";
      serif = "NotoSerif Nerd Font";
      emoji = "Noto Color Emoji";
    };

    size = builtins.floor (design_factor * 0.75); # 12
  };

  cursor = {
    theme = {
      name = "hyprcursor";
      package = pkgs.hyprcursor;
    };

    size = builtins.floor (design_factor * 1.50); # 24
  };

  nix-rice = builtins.fetchTarball "https://github.com/bertof/nix-rice/archive/refs/heads/main.tar.gz";
  nix-rice-lib = import (nix-rice + "/lib.nix") {
    lib = pkgs.lib;
    kitty-themes-src = null;
  };

  convert_hex_color_code_to_rgba_color_code =
    hex_color:
    let
      color_set = nix-rice-lib.color.hexToRgba hex_color;

      red = builtins.floor color_set.r;
      green = builtins.floor color_set.g;
      blue = builtins.floor color_set.b;
      alpha = builtins.floor (color_set.a / 255);
    in
    "rgba(${toString red}, ${toString green}, ${toString blue}, ${toString alpha})";

  fetched_gtk_css_file = builtins.fetchurl {
    url = "https://gitlab.gnome.org/GNOME/gtk/-/raw/gtk-3-24/gtk/theme/Adwaita/gtk-contained-dark.css";
  };
  gtk_css_file = builtins.readFile fetched_gtk_css_file;
  gtk_css_lines = builtins.filter (x: builtins.isString x) (builtins.split "\n" gtk_css_file);

  gtk_css_color_lines = builtins.filter (
    line: builtins.match "^@define-color [^ ]+ [^;]+;" line != null
  ) gtk_css_lines;
  gtk_color_list = builtins.filter (x: x != null) (
    builtins.map (
      line:
      let
        mapping = builtins.match "@define-color ([^ ]+) ([^;]+);" line;
      in
      if mapping == null then
        null
      else
        {
          name = builtins.elemAt mapping 0;
          value = builtins.elemAt mapping 1;
        }
    ) gtk_css_color_lines
  );
  gtk_color_attributes = builtins.listToAttrs gtk_color_list;

  colors = {
    hex = {
      borders = gtk_color_attributes.borders;
      unfocused_borders = gtk_color_attributes.unfocused_borders;

      background = gtk_color_attributes.theme_bg_color;
      base_background = gtk_color_attributes.theme_base_color;
      selected_background = gtk_color_attributes.theme_selected_bg_color;
      unfocused_background = gtk_color_attributes.theme_unfocused_bg_color;
      unfocused_base_background = gtk_color_attributes.theme_unfocused_base_color;
      unfocused_selected_background = gtk_color_attributes.theme_unfocused_selected_bg_color;
      insensitive_background = gtk_color_attributes.insensitive_bg_color;
      insensitive_base_background = gtk_color_attributes.insensitive_base_color;
      content_view_background = gtk_color_attributes.content_view_bg;
      text_view_background = gtk_color_attributes.text_view_bg;

      foreground = gtk_color_attributes.theme_fg_color;
      selected_foreground = gtk_color_attributes.theme_selected_fg_color;
      insensitive_foreground = gtk_color_attributes.insensitive_fg_color;
      text = gtk_color_attributes.theme_text_color;
      unfocused_foreground = gtk_color_attributes.theme_unfocused_fg_color;
      unfocused_selected_foreground = gtk_color_attributes.theme_unfocused_selected_fg_color;
      unfocused_insensitive_color = gtk_color_attributes.unfocused_insensitive_color;
      unfocused_text = gtk_color_attributes.theme_unfocused_text_color;

      warning = gtk_color_attributes.warning_color;
      error = gtk_color_attributes.error_color;
      success = gtk_color_attributes.success_color;
    };
  };

  design_factor = 16;

  secrets = import ./secrets.nix;
in
{
  imports = [
    (import "${home-manager}/nixos")

    dankmaterialshellPluginRegistryFlake.modules.default

    ./hardware-configuration.nix
  ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      timeout = 2;

      systemd-boot = {
        enable = true;
        consoleMode = "max";
        configurationLimit = null;

        memtest86.enable = true;
      };
    };

    kernel = {
      enable = true;

      sysctl = {
        "net.ipv4.tcp_syncookies" = true;
      };
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_6_18;

    extraModulePackages = with config.boot.kernelPackages; [
      openafs
      apfs
      cpupower
      mm-tools
      tmon
      turbostat
      usbip
      zfs_unstable
    ];

    kernelModules = [
      "at24"
      "ee1004"
      "kvm-intel"
      "spd5118"
    ];

    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm report_ignored_msrs=0
    '';

    kernelParams = [
      "boot.shell_on_fail"
      "intel_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "mitigations=auto"
      "rd.systemd.show_status=true"
      "rd.udev.log_level=err"
      "udev.log_level=err"
      "udev.log_priority=err"
    ];

    initrd = {
      enable = true;

      kernelModules = config.boot.kernelModules;

      systemd = {
        enable = true;
        package = config.systemd.package;
      };

      network.ssh.enable = true;

      verbose = true;
    };

    consoleLogLevel = 4; # 4 = KERN_WARNING

    tmp.cleanOnBoot = true;

    plymouth = {
      enable = true;

      themePackages = [
        pkgs.nixos-bgrt-plymouth
      ];
      theme = "nixos-bgrt";

      font = "${pkgs.nerd-fonts.noto}/share/fonts/truetype/NerdFonts/Noto/NotoSansNerdFont-Regular.ttf";

      extraConfig = ''
        UseFirmwareBackground=true
      '';
    };
  };

  time = {
    timeZone = "Asia/Dhaka";
    hardwareClockInLocalTime = true;
  };

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

    # activationScripts = { };

    # userActivationScripts = { };

    stateVersion = "26.05";
  };

  nix = {
    enable = true;
    channel.enable = true;

    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operators"
      ];

      require-sigs = true;
      sandbox = true;
      auto-optimise-store = true;

      cores = 0; # 0 = All
      max-jobs = 1;
    };

    gc = {
      automatic = true;
      dates = "weekly";
      persistent = true;
    };
  };

  nixpkgs = {
    hostPlatform = "x86_64-linux";

    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;
    };

    # overlays = [ ];
  };

  appstream.enable = true;

  i18n = {
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

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        waylandFrontend = true;

        addons = with pkgs; [
          fcitx5-gtk
          fcitx5-openbangla-keyboard
        ];
      };
    };
  };

  networking = {
    enableIPv6 = true;

    domain = "local";
    hostName = "Bitscoper-WorkStation";
    fqdn = "${config.networking.hostName}.${config.networking.domain}";

    wireless = {
      dbusControlled = true;
      userControlled = true;
    };

    networkmanager = {
      enable = true;
      package = (
        pkgs.networkmanager.override {
          withSystemd = true;
        }
      );

      ethernet.macAddress = "permanent";

      wifi = {
        backend = "wpa_supplicant";

        powersave = false;

        scanRandMacAddress = true;
        macAddress = "permanent";
      };

      logLevel = "WARN";
    };

    firewall = {
      enable = false;

      allowPing = true;

      allowedTCPPorts = [
        5900 # VNC
      ];
      allowedUDPPorts = [
        5900 # VNC
      ];
    };

    nameservers = [
      "1.1.1.3#one.one.one.one"
      "1.0.0.3#one.one.one.one"
    ];

    timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];
  };

  security = {
    allowSimultaneousMultithreading = true;

    tpm2.enable = true;

    lockKernelModules = false;

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

      services = {
        login = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };
        };

        sudo = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;
        };

        polkit-1 = {
          unixAuth = true;
          nodelay = false;

          fprintAuth = true;

          logFailures = true;
        };
      };
    };

    sudo = {
      enable = true;
      package = (
        pkgs.sudo.override {
          withInsults = true;
        }
      );

      execWheelOnly = true;
      wheelNeedsPassword = true;
    };

    polkit = {
      enable = true;
      package = (
        pkgs.polkit.override {
          useSystemd = true;
        }
      );
    };

    rtkit.enable = true;

    wrappers = {
      spice-client-glib-usb-acl-helper.source = "${
        (pkgs.spice-gtk.override {
          withPolkit = true;
        })
      }/bin/spice-client-glib-usb-acl-helper";
    };

    audit = {
      enable = false;
    };

    auditd = {
      enable = false;
    };
  };

  hardware = {
    enableAllFirmware = true; # Unfree
    enableRedistributableFirmware = true;
    firmware = with pkgs; [
      alsa-firmware
      linux-firmware
      sof-firmware
    ];

    cpu = {
      intel = {
        updateMicrocode = true;
      };
    };

    i2c = {
      enable = true;
      group = "i2c";
    };

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = with pkgs; [
        intel-media-driver
        intel-compute-runtime
      ];
    };

    sensor = {
      hddtemp = {
        enable = true;
        unit = "C";
        drives = [
          "/dev/disk/by-path/*"
        ];
      };
    };

    bluetooth = {
      enable = true;
      package = (
        pkgs.bluez.override {
          enableExperimental = true;
        }
      );

      hsphfpd.enable = false; # Conflicts wwth WirePlumber

      powerOnBoot = true;

      input.General = {
        IdleTimeout = 0; # 0 = Disabled
        LEAutoSecurity = true;
        ClassicBondedOnly = true;
        UserspaceHID = true;
      };

      network.General = {
        DisableSecurity = false;
      };

      settings = {
        General = {
          MaxControllers = 0; # 0 = Unlimited
          ControllerMode = "dual";

          Name = config.networking.hostName;

          DiscoverableTimeout = 0; # 0 = Disabled
          PairableTimeout = 0; # 0 = Disabled
          AlwaysPairable = true;
          FastConnectable = true;

          ReverseServiceDiscovery = true;
          NameResolving = true;
          RemoteNameRequestRetryDelay = 60; # 1 Minute
          RefreshDiscovery = true;
          TemporaryTimeout = 0; # 0 = Disabled

          SecureConnections = "on";
          Privacy = "off";

          Experimental = true; # Shows Battery Percentage
          KernelExperimental = true;
        };

        Policy = {
          AutoEnable = true;

          ResumeDelay = 2; # Seconds
          ReconnectAttempts = 7;
          ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        };

        GATT = {
          Cache = "always";
        };

        CSIS = {
          Encryption = true;
        };

        AVRCP = {
          VolumeCategory = true;
          VolumeWithoutTarget = false;
        };

        AVDTP = {
          SessionMode = "ertm";
        };

        AdvMon = {
          RSSISamplingPeriod = "0x00";
        };
      };
    };

    sane = {
      enable = true;
      backends-package = (
        pkgs.sane-backends.override {
          withSystemd = true;
        }
      );
      # extraBackends = with pkgs; [ ];
      snapshot = false;

      openFirewall = true;
    };

    rtl-sdr = {
      enable = true;
      package = pkgs.rtl-sdr;
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      package = pkgs.libvirt;

      qemu = {
        package = (
          pkgs.qemu_kvm.override {
            guestAgentSupport = true;
            alsaSupport = true;
            pulseSupport = true;
            pipewireSupport = true;
            sdlSupport = true;
            jackSupport = true;
            gtkSupport = true;
            vncSupport = true;
            smartcardSupport = true;
            spiceSupport = true;
            usbredirSupport = true;
            glusterfsSupport = true;
            openGLSupport = true;
            rutabagaSupport = true;
            virglSupport = true;
            libiscsiSupport = true;
            smbdSupport = true;
            tpmSupport = true;
            uringSupport = true;
            pluginsSupport = true;
            enableDocs = true;
            enableTools = true;
            enableBlobs = true;
          }
        );

        swtpm = {
          enable = true;
          package = pkgs.swtpm;
        };

        runAsRoot = true;
      };
    };
    spiceUSBRedirection.enable = true;

    containers.enable = true;

    docker = {
      enable = true;
      package = (
        pkgs.docker_29.override {
          buildxSupport = true;
          composeSupport = true;
          sbomSupport = true;
          initSupport = true;

          withSystemd = true;
          withBtrfs = true;
          withLvm = true;
          withSeccomp = true;
        }
      );

      logDriver = "journald";

      listenOptions = [
        "/run/docker.sock"
      ];

      daemon.settings = {
        ipv6 = true;

        live-restore = true;
      };

      enableOnBoot = true;
    };

    oci-containers.backend = "docker";

    waydroid = {
      enable = true;
      package = pkgs.waydroid;
    };
  };

  systemd = {
    package = (
      pkgs.systemd.override {
        withAcl = true;
        withCryptsetup = true;
        withDocumentation = true;
        withLogind = true;
        withOpenSSL = true;
        withPam = true;
        withPolkit = true;
      }
    );

    packages = with pkgs; [
      (hardinfo2.override {
        printingSupport = true;
      })
    ];

    services = {
      hardinfo2_custom = {
        description = "Hardinfo2 support for root access";
        wantedBy = [ "basic.target" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.hardinfo2}/bin/hwinfo2_fetch_sysdata"; # The ${pkgs.hardinfo2}/lib/systemd/system/hardinfo2.service file intends to run ${pkgs.hardinfo2}/bin/hwinfo2_fetch_sysdata oneshot which calls ${pkgs.hardinfo2}/bin/.hwinfo2_fetch_sysdata-wrapped
        };

        enable = true;
      };
    }; # Custom Service Unit File due to Errors
  };

  services = {
    upower = {
      enable = true;
      package = pkgs.upower;

      allowRiskyCriticalPowerAction = false;
      criticalPowerAction = "PowerOff";

      ignoreLid = true;
    };

    thermald = {
      enable = true;
      package = pkgs.thermald;

      ignoreCpuidCheck = false;

      debug = false;
    };

    power-profiles-daemon = {
      enable = true;
      package = pkgs.power-profiles-daemon;
    };

    acpid = {
      enable = true;

      # powerEventCommands = '''';
      # acEventCommands = '''';
      # lidEventCommands = '''';

      logEvents = false;
    };

    logind = {
      settings = {
        Login = {
          killUserProcesses = true;

          lidSwitch = "ignore";
          lidSwitchDocked = "ignore";
          lidSwitchExternalPower = "ignore";

          powerKey = "poweroff";
          powerKeyLongPress = "poweroff";

          rebootKey = "reboot";
          rebootKeyLongPress = "reboot";

          suspendKey = "suspend";
          suspendKeyLongPress = "suspend";

          hibernateKey = "hibernate";
          hibernateKeyLongPress = "hibernate";
        };
      };
    };

    dbus = {
      enable = true;
      dbusPackage = (
        pkgs.dbus.override {
          enableSystemd = true;
        }
      );

      implementation = "broker";
    };

    timesyncd = {
      enable = true;

      servers = config.networking.timeServers;
      fallbackServers = config.networking.timeServers;
    };

    fwupd = {
      enable = true;
      package = (
        pkgs.fwupd.override {
          enableFlashrom = true;
        }
      );
    };

    udev = {
      enable = true;
      packages = with pkgs; [
        game-devices-udev-rules
        libmtp.out
        rtl-sdr
      ];
    };

    udisks2 = {
      enable = true;
      package = pkgs.udisks2;

      mountOnMedia = false;
    };

    fprintd = {
      enable = true;
      package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;
      # tod = {
      #   enable = true;
      #   driver = ;
      # };
    };

    displayManager = {
      enable = true;

      dms-greeter = {
        enable = true;
        package = pkgs.dms-shell;

        quickshell.package = pkgs.quickshell;
        # quickshell.package = quickshellFlake.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

        compositor =
          let
            hyprlandConfigurationFile = pkgs.writeText "hyprland.conf" ''
              monitor=, highres, auto, 1, transform, 0
              monitor=eDP-1, highres, auto, 1, transform, 0
              monitor=HDMI-A-1, highres, auto, 1, transform, 1
            '';
          in
          {
            name = "hyprland";
            customConfig = builtins.readFile hyprlandConfigurationFile;
          };

        configHome = "/home/bitscoper";

        logs = {
          save = true;
        };
      };

      logToJournal = true;
    };

    gnome = {
      gnome-keyring.enable = true;

      gcr-ssh-agent = {
        enable = true;
        package = pkgs.gcr_4;
      };

      sushi.enable = true;
    };

    gvfs = {
      enable = true;
      package = (
        pkgs.gvfs.override {
          udevSupport = true;
        }
      );
    };

    pipewire = {
      enable = true;
      package = (
        pkgs.pipewire.override {
          enableSystemd = true;
          vulkanSupport = true;
          bluezSupport = true;
          zeroconfSupport = true;
          raopSupport = true;
          rocSupport = true;
        }
      );

      extraLv2Packages = with pkgs; [
        lsp-plugins
      ];

      systemWide = false;

      audio.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      socketActivation = true;

      wireplumber = {
        enable = true;
        package = (
          pkgs.wireplumber.override {
            enableDocs = true;
          }
        );

        extraLv2Packages = config.services.pipewire.extraLv2Packages;

        extraConfig.bluetoothEnhancements = {
          "monitor.bluez.properties" = {
            "bluez5.enable-hw-volume" = true;

            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;

            "bluez5.roles" = [
              "a2dp_sink"
              "a2dp_source"
              "bap_sink"
              "bap_source"
              "hfp_ag"
              "hfp_hf"
              "hsp_ag"
              "hsp_hs"
            ];

            "bluez5.codecs" = [
              "aac"
              "aptx"
              "aptx_hd"
              "aptx_ll"
              "aptx_ll_duplex"
              "faststream"
              "faststream_duplex"
              "lc3"
              "lc3plus_h3"
              "ldac"
              "opus_05"
              "opus_05_51"
              "opus_05_71"
              "opus_05_duplex"
              "opus_05_pro"
              "sbc"
              "sbc_xq"
            ];
          };
        };
      };

      raopOpenFirewall = true;
    };

    pulseaudio.enable = false;

    phpfpm = {
      phpPackage =
        (pkgs.php.override {
          cgiSupport = true;
          cliSupport = true;
          fpmSupport = true;
          pearSupport = true;
          pharSupport = true;
          phpdbgSupport = true;
          argon2Support = true;
          cgotoSupport = true;
          staticSupport = true;
          ipv6Support = true;
          zendSignalsSupport = true;
          zendMaxExecutionTimersSupport = false;
          systemdSupport = true;
          valgrindSupport = true;
          ztsSupport = true;
        }).buildEnv
          {
            extensions =
              {
                enabled,
                all,
              }:
              enabled
              ++ (with all; [
                bz2
                calendar
                ctype
                curl
                dba
                dom
                exif
                ffi
                fileinfo
                filter
                ftp
                gd
                iconv
                imagick
                imap
                mailparse
                memcached
                mysqli
                mysqlnd
                opcache
                openssl
                pcntl
                pdo
                pdo_mysql
                pdo_pgsql
                pgsql
                posix
                session
                sockets
                sodium
                systemd
                xdebug
                xml
                xmlreader
                xmlwriter
                xsl
                zip
                zlib
              ]);

            extraConfig = config.services.phpfpm.phpOptions;
          };

      settings = {
        log_level = "warning";
      };

      phpOptions = ''
        default_charset = "UTF-8"
        error_reporting = E_ALL
        display_errors = Off
        log_errors = On
        cgi.force_redirect = 1
        expose_php = Off
        file_uploads = On
        session.cookie_lifetime = 0
        session.use_cookies = 1
        session.use_only_cookies = 1
        session.use_strict_mode = 1
        session.cookie_httponly = 1
        session.cookie_secure = 1
        session.cookie_samesite = "Strict"
        session.gc_maxlifetime = 43200
        session.use_trans_sid = O
        session.cache_limiter = nocache
        xdebug.mode=debug
      '';
    };

    avahi = {
      enable = true;
      package = (
        pkgs.avahi.override {
          gtk3Support = true;
        }
      );

      ipv4 = true;
      ipv6 = true;

      nssmdns4 = true;
      nssmdns6 = true;

      wideArea = false;

      publish = {
        enable = true;

        domain = true;
        addresses = true;
        workstation = true;
        hinfo = true;
        userServices = true;
      };

      domainName = config.networking.domain;
      hostName = config.networking.hostName;

      openFirewall = true;
    };

    openssh = {
      enable = true;
      package = (
        pkgs.openssh.override {
          withPAM = true;
          linkOpenssl = true;
          isNixos = true;
        }
      );

      listenAddresses = [
        {
          addr = "0.0.0.0";
        }
        {
          addr = "::";
        }
      ];
      ports = [
        22
      ];
      allowSFTP = true;

      banner = config.networking.fqdn;

      authorizedKeysInHomedir = true;

      settings = {
        PermitRootLogin = "yes";
        PasswordAuthentication = true;
        X11Forwarding = false;
        StrictModes = true;
        UseDns = true;
        LogLevel = "ERROR";
      };

      openFirewall = true;
    };
    sshd.enable = true;

    cockpit = {
      enable = true;
      package = pkgs.cockpit;

      port = 9090;
      allowed-origins = [
        "*"
      ];

      settings = {
        WebService = {
          AllowUnencrypted = false;

          LoginTo = true;
          AllowMultiHost = true;
        };
      };

      openFirewall = true;
    };

    printing = {
      enable = true;
      package = (
        pkgs.cups.override {
          enableSystemd = true;
        }
      );

      drivers = with pkgs; [
        (gutenprint.override {
          cupsSupport = true;
        })
        gutenprintBin
      ];

      cups-pdf.enable = true;

      listenAddresses = [
        "*:631"
      ];

      allowFrom = [
        "all"
      ];

      browsing = true;
      webInterface = true;

      defaultShared = true;
      startWhenNeeded = true;

      extraConf = ''
        DefaultLanguage en
        ServerName ${config.networking.fqdn}
        ServerAlias *
        ServerTokens Full
        ServerAdmin bitscoper@${config.networking.fqdn}
        BrowseLocalProtocols all
        BrowseWebIF On
        HostNameLookups On
        AccessLogLevel config
        AutoPurgeJobs Yes
        PreserveJobHistory Off
        PreserveJobFiles Off
        DirtyCleanInterval 30
        LogTimeFormat standard
      '';

      logLevel = "warn";

      openFirewall = true;
    };
    ipp-usb.enable = true;
    system-config-printer.enable = true;

    saned = {
      enable = true;
    };

    gpsd = {
      enable = true;

      readonly = true;

      listenany = true;
      port = 2947;
    };

    bind = {
      enable = false;
      package = pkgs.bind;

      listenOn = [
        "any"
      ];
      ipv4Only = false;
      listenOnIpv6 = [
        "any"
      ];

      cacheNetworks = [
        "127.0.0.0/24"
        "::1/128"
      ];

      extraOptions = ''
        recursion no;
      '';
    };

    memcached = {
      enable = true;
      listen = "*";
      port = 11211;
      enableUnixSocket = false;
      maxMemory = 64; # Megabytes
      maxConnections = 256;
    };

    postgresql = {
      enable = true;
      package = pkgs.postgresql_18_jit;

      enableTCPIP = true;

      settings = pkgs.lib.mkForce {
        listen_addresses = "*";
        port = 5432;
        jit = true;
      };

      authentication = pkgs.lib.mkOverride 10 ''
        local all all md5
        host all all 0.0.0.0/0 md5
        host all all ::/0 md5
        local replication all md5
        host replication all 0.0.0.0/0 md5
        host replication all ::/0 md5
      '';

      checkConfig = true;

      initialScript = pkgs.writeText "initScript" ''
        ALTER USER postgres WITH PASSWORD '${secrets.password_1_of_bitscoper}';
      '';
    };

    mysql = {
      enable = true;
      package = pkgs.mariadb_118;

      settings = {
        mysqld = {
          bind-address = "*";
          port = 3306;

          sql_mode = "";
        };
      };

      initialScript = pkgs.writeText "initScript" ''
        grant all privileges on *.* to 'root'@'%' identified by password '${secrets.hashed_password_1_of_bitscoper}' with grant option;
        DELETE FROM mysql.user WHERE `Host`='localhost' AND `User`='root';
        flush privileges;
      '';
    };

    postfix = {
      enable = true;

      enableSmtp = true;
      enableSubmission = true;
      enableSubmissions = true;

      virtualMapType = "pcre";
      aliasMapType = "pcre";
      enableHeaderChecks = true;

      setSendmail = true;

      settings = {
        main = {
          mydomain = config.networking.fqdn;
          myhostname = config.networking.fqdn;
          myorigin = config.networking.fqdn;
        };
      };
    };

    opendkim = {
      enable = true;

      domains = "csl:${config.networking.fqdn}";
      selector = "default";

      # settings = { };
    };

    dovecot2 = {
      enable = true;

      enableImap = true;
      enableLmtp = true;
      enablePop3 = false;
      protocols = [
        "imap"
        "lmtp"
      ];

      enableQuota = true;
      quotaPort = "12340";

      enableDHE = true;

      createMailUser = true;

      enablePAM = true;
      showPAMFailure = true;

      # pluginSettings = {};
    };

    icecast = {
      enable = true;

      hostname = config.networking.fqdn;
      listen = {
        address = "0.0.0.0";
        port = 17101;
      };

      admin = {
        user = "bitscoper";
        password = secrets.password_1_of_bitscoper;
      };

      extraConfig = ''
        <location>${config.networking.fqdn}</location>
        <admin>bitscoper@${config.networking.fqdn}</admin>
        <authentication>
          <source-password>${secrets.password_2_of_bitscoper}</source-password>
          <relay-password>${secrets.password_2_of_bitscoper}</relay-password>
        </authentication>
        <directory>
          <yp-url-timeout>15</yp-url-timeout>
          <yp-url>http://dir.xiph.org/cgi-bin/yp-cgi</yp-url>
        </directory>
        <logging>
          <loglevel>2</loglevel>
        </logging>
        <server-id>${config.networking.fqdn}</server-id>
      ''; # <loglevel>2</loglevel> = Warn
    };

    jellyfin = {
      enable = true;
      package = pkgs.jellyfin;

      openFirewall = true;
    };

    ollama = {
      enable = true;
      package = pkgs.ollama-cpu; # Or pkgs.ollama-vulkan Or pkgs.ollama

      host = "0.0.0.0";
      port = 11434;
      openFirewall = true;
    };

    tailscale = {
      enable = true;
      package = pkgs.tailscale;

      disableTaildrop = false;

      port = 0; # 0 = Automatic
      openFirewall = true;
    };

    kubernetes = {
      package = pkgs.kubernetes;
    };

    logrotate = {
      enable = true;

      checkConfig = true;
      allowNetworking = true;
    };
  };

  programs = {
    foot = {
      enable = true;
      package = pkgs.foot;

      enableBashIntegration = true;

      settings = {
        main = {
          font = "${font_preferences.name.mono}:pixelsize=${toString design_factor}";
        };

        security.osc52 = "enabled";

        bell = {
          system = "yes";
        };
      };
    };

    command-not-found.enable = true;

    nix-ld = {
      enable = true;
      package = pkgs.nix-ld;

      libraries =
        options.programs.nix-ld.libraries.default
        ++ (with pkgs; [
          glib.out
          llvmPackages.stdenv.cc.cc.lib
          stdenv.cc.cc.lib
        ]);
    };

    java = {
      enable = true;
      package = (
        pkgs.jdk.override {
          enableGtk = true;
        }
      );

      binfmt = true;
    };

    appimage = {
      enable = true;
      package = (
        pkgs.appimage-run.override {
          extraPkgs =
            pkgs: with pkgs; [
              libepoxy
            ];
        }
      );

      binfmt = true;
    };

    uwsm = {
      enable = true;
      package = (
        pkgs.uwsm.override {
          fumonSupport = true;
          uuctlSupport = true;
          uwsmAppSupport = true;
        }
      );
    };

    hyprland = {
      enable = true;
      package = (
        pkgs.hyprland.override {
          enableXWayland = true;
          wrapRuntimeDeps = true;
        }
      );
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      withUWSM = true;
      xwayland.enable = true;
    };

    dms-shell = {
      enable = true;
      package = pkgs.dms-shell;

      # quickshell.package = pkgs.quickshell;
      quickshell.package = quickshellFlake.packages.${pkgs.stdenv.hostPlatform.system}.quickshell;

      systemd = {
        enable = true;
        restartIfChanged = true;
      };

      enableAudioWavelength = true;
      enableCalendarEvents = true;
      enableClipboardPaste = true;
      enableDynamicTheming = true;
      enableSystemMonitoring = true;
      enableVPN = true;

      plugins = {
        calculator.enable = true;
        dankHooks.enable = true;
        dockerManager.enable = true;
        emojiLauncher.enable = true;
        hyprlandSubmap.enable = true;
        kubernetes.enable = true;
        nixMonitor.enable = true;
        prayerTimes.enable = true;
        tailscale.enable = true;
      }; # From dankmaterialshellPluginRegistryFlake
    };

    dsearch = {
      enable = true;
      package = pkgs.dsearch;

      systemd = {
        enable = true;
      };
    };

    xwayland.enable = true;

    bash = {
      vteIntegration = true;

      blesh.enable = true;

      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };

      enableLsColors = true;

      undistractMe = {
        enable = true;
        playSound = true;
      };

      # shellAliases = { };

      # loginShellInit = '''';
      # shellInit = '''';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';
    };

    zoxide = {
      enable = true;
      package = (
        pkgs.zoxide.override {
          withFzf = true;
        }
      );

      enableBashIntegration = true;

      flags = [
        "--cmd cd"
      ];
    };

    direnv = {
      enable = true;
      package = pkgs.direnv;

      nix-direnv.enable = true;
      loadInNixShell = true;

      enableBashIntegration = true;

      silent = false;
    };

    nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
    };

    gnupg = {
      package = (
        pkgs.gnupg.override {
          guiSupport = true;
          withTpm2Tss = true;
        }
      );

      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;

        pinentryPackage = (
          pkgs.pinentry-gtk2.override {
            withLibsecret = true;
          }
        );
      };

      dirmngr.enable = true;
    };

    ssh = {
      package = (
        pkgs.openssh.override {
          withPAM = true;
          linkOpenssl = true;
          isNixos = true;
        }
      );

      startAgent = false; # `services.gnome.gcr-ssh-agent.enable' and `programs.ssh.startAgent' cannot both be enabled at the same time.
      agentTimeout = null;
    };

    git = {
      enable = true;
      package = (
        pkgs.gitFull.override {
          svnSupport = true;
          guiSupport = true;
          withManual = true;
          withpcre2 = true;
          sendEmailSupport = true;
          withLibsecret = true;
          withSsh = true;
        }
      );

      lfs = {
        enable = true;
        package = pkgs.git-lfs;

        enablePureSSHTransfer = true;
      };

      prompt.enable = true;

      config = {
        init.defaultBranch = "main";

        credential.helper = "${pkgs.gitFull}/bin/git-credential-libsecret";

        user = {
          name = "Abdullah As-Sadeed";
          email = "bitscoper@protonmail.com";
        };
      };
    };

    usbtop.enable = true;

    nano.enable = false;

    neovim = {
      enable = true;
      package = pkgs.neovim-unwrapped;

      withPython3 = true;

      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
    };

    bat = {
      enable = true;
      package = pkgs.bat;
      extraPackages = with pkgs.bat-extras; [
        batgrep
        batdiff
        batman
        batpipe
        batwatch
        prettybat
      ];
    };

    gnome-disks.enable = true;

    system-config-printer.enable = true;

    seahorse.enable = true;

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "foot";
    };

    firefox = {
      enable = true;
      package = pkgs.firefox-devedition;
      languagePacks = [
        "bn"
        "en-US"
      ];

      policies = {
        Extensions = {
          Install = [
            "https://addons.mozilla.org/firefox/downloads/latest/decentraleyes/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/languagetool/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/multi-account-containers/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/search_by_image/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/simple-mass-downloader/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/single-file/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/tab-disguiser/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
            "https://addons.mozilla.org/firefox/downloads/latest/zjm-whatfont/latest.xpi"
          ];

          Locked = [
            "@testpilot-containers" # "Firefox Multi-Account Containers"
          ];
        };
      };

      # autoConfig = '''';

      preferences = {
        "browser.contentblocking.category" = "strict";
        "browser.search.region" = "BD";
        "browser.search.suggest.enabled.private" = true;
        "dom.security.https_only_mode" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "security.warn_submit_secure_to_insecure" = true;
        # "privacy.fingerprintingProtection" = true;
        # "privacy.trackingprotection.enabled" = true;
      };
      preferencesStatus = "locked";
    };

    thunderbird = {
      enable = true;
      package = pkgs.thunderbird-latest;

      # preferences = { };
    };

    obs-studio = {
      enable = true;
      package = (
        pkgs.obs-studio.override {
          scriptingSupport = true;
          alsaSupport = true;
          pulseaudioSupport = true;
          browserSupport = true;
          pipewireSupport = true;
          withFdk = true;
        }
      );

      enableVirtualCamera = true;

      plugins = with pkgs.obs-studio-plugins; [
        obs-3d-effect
        obs-backgroundremoval
        obs-composite-blur
        obs-gradient-source
        obs-gstreamer
        obs-move-transition
        obs-multi-rtmp
        obs-mute-filter
        obs-pipewire-audio-capture
        obs-scale-to-sound
        obs-source-clone
        obs-source-record
        obs-source-switcher
        obs-text-pthread
        obs-transition-table
        obs-vaapi
        obs-vkcapture
      ];
    };

    # ghidra = {
    #   enable = true;
    #   package = pkgs.ghidra;
    #   gdb = true;
    # }; # FIXME: Build Failure

    wireshark = {
      enable = true;
      package = pkgs.wireshark;

      dumpcap.enable = true;
      usbmon.enable = true;
    };

    localsend = {
      enable = true;
      package = pkgs.localsend;

      openFirewall = true;
    };

    virt-manager = {
      enable = true;
      package = (
        pkgs.virt-manager.override {
          spiceSupport = true;
        }
      );
    };

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "org/gnome/desktop/interface" = {
              color-scheme = "prefer-dark";
            };

            "com/saivert/pwvucontrol" = {
              beep-on-volume-changes = true;
              enable-overamplification = true;
            };

            "org/gnome/desktop/privacy" = {
              remember-app-usage = false;
              remember-recent-files = false;
              remove-old-temp-files = true;
              remove-old-trash-files = true;
              report-technical-problems = false;
              send-software-usage-stats = false;
              usb-protection = true;
            };

            "org/gtk/gtk4/settings/file-chooser" = {
              sort-directories-first = true;
            };

            "org/gnome/nautilus/preferences" = {
              click-policy = "double";
              recursive-search = "always";
              show-create-link = true;
              show-delete-permanently = true;
              show-directory-item-counts = "always";
              show-image-thumbnails = "always";
              date-time-format = "simple";
            };

            "org/gnome/nautilus/icon-view" = {
              captions = [
                "size"
                "date_modified"
                "none"
              ];
            };

            "org/gnome/file-roller/ui" = {
              view-sidebar = true;
            };

            "org/gnome/eog/plugins" = {
              active-plugins = [
                "fullscreen"
                "reload"
                "statusbar-date"
              ];
            };

            "org/gnome/eog/ui" = {
              image-gallery = false;
              sidebar = true;
              statusbar = true;
            };

            "org/gnome/eog/view" = {
              autorotate = true;
              extrapolate = true;
              interpolate = true;
              transparency = "checked";
              use-background-color = false;
            };

            "org/gnome/eog/fullscreen" = {
              loop = false;
              upscale = false;
            };

            "com/github/huluti/Curtail" = {
              file-attributes = true;
              metadata = false;
              new-file = true;
              recursive = true;
            };

            "com/github/tenderowl/frog" = {
              telemetry = false;
            };

            "org/gnome/meld" = {
              enable-space-drawer = true;
              highlight-current-line = true;
              highlight-syntax = true;
              prefer-dark-theme = true;
              show-line-numbers = true;
              show-overview-map = true;
              wrap-mode = "word";
            };

            "io/gitlab/adhami3310/Converter" = {
              show-less-popular = true;
            };

            "org/virt-manager/virt-manager" = {
              xmleditor-enabled = true;
            };

            "org/virt-manager/virt-manager/connections" = {
              autoconnect = [
                "qemu:///system"
              ];
              uris = [
                "qemu:///system"
              ];
            };

            "org/virt-manager/virt-manager/new-vm" = {
              cpu-default = "host-passthrough";
            };

            "org/virt-manager/virt-manager/console" = {
              auto-redirect = false;
              autoconnect = true;
            };

            "org/virt-manager/virt-manager/stats" = {
              enable-cpu-poll = true;
              enable-disk-poll = true;
              enable-memory-poll = true;
              enable-net-poll = true;
            };

            "org/virt-manager/virt-manager/vmlist-fields" = {
              cpu-usage = true;
              disk-usage = true;
              host-cpu-usage = true;
              memory-usage = true;
              network-traffic = true;
            };

            "org/virt-manager/virt-manager/confirm" = {
              delete-storage = true;
              forcepoweroff = true;
              pause = true;
              poweroff = true;
              removedev = true;
              unapplied-dev = true;
            };

            "system/locale" = {
              region = "en_US.UTF-8";
            };
          };
        }
      ];
    };
  };

  fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      corefonts # Unfree
      nerd-fonts.noto
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-cjk-serif
      noto-fonts-color-emoji
      noto-fonts-lgc-plus
    ];

    fontconfig = {
      enable = true;

      allowBitmaps = true;
      allowType1 = false;
      cache32Bit = true;

      defaultFonts = {
        monospace = [
          font_preferences.name.mono
        ];

        sansSerif = [
          font_preferences.name.sans_serif
        ];

        serif = [
          font_preferences.name.serif
        ];

        emoji = [
          font_preferences.name.emoji
        ];
      };

      includeUserConf = true;
    };
  };

  environment = {
    enableDebugInfo = false;

    enableAllTerminfo = true;

    wordlist = {
      enable = true;
      # lists = ;
    };

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    variables = {
      ANDROID_SDK_ROOT = android_sdk_path;
      ANDROID_HOME = android_sdk_path;

      LD_LIBRARY_PATH = lib.mkForce "${
        pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            sqlite
          ]
        )
      }:$LD_LIBRARY_PATH";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };

    shellAliases = {
      firefox = "firefox-devedition";
      code = "codium";

      fetch_upgrade_data = "sudo nix-channel --update && sudo nix-env -u --always";

      upgrade = "sudo nix-channel --update && sudo nix-env -u --always && sudo nixos-rebuild switch --refresh --install-bootloader --upgrade-all";

      clean_upgrade = "sudo nix-channel --update && sudo nix-env -u --always && sudo rm -rf /nix/var/nix/gcroots/auto/* && sudo nix-env --delete-generations old && sudo nix-collect-garbage -d && sudo nix-store --gc && sudo nix-store --optimise && sudo nixos-rebuild switch --refresh --install-bootloader --upgrade-all";
    };

    # extraInit = '''';
    # loginShellInit = '''';
    # shellInit = '''';
    # interactiveShellInit = '''';

    systemPackages =
      with pkgs;
      [
        # armitage # FIXME: Build Failure
        # autopsy # FIXME: Build Failure
        # bulk_extractor # FIXME: Build Failure
        # certbot-full # FIXME: Build Failure
        # dart # flutter adds the compatible versions
        # debase # FIXME: Build Failure
        # freecad # FIXME: Build Failure
        # reiser4progs # Marked Broken
        # xfstests # FIXME: Build Failure
        aapt
        above
        acl
        acpica-tools
        acpidump-all
        adb-sync
        addlicense
        agi # FIXME: Cannot find libswt
        aircrack-ng
        alpaca
        alsa-plugins
        alsa-tools
        alsa-utils
        alsa-utils-nhlt
        android_sdk # Custom
        android-backup-extractor
        android-tools
        apfsprogs
        apitrace
        apkeep
        apkleaks
        arduino-cli
        arduino-ide
        arduino-language-server
        asciinema
        asciinema-agg
        asciinema-scenario
        audacity
        avrdude
        banner
        baobab
        bash-language-server
        bcachefs-tools
        binary
        binutils
        binwalk
        bleachbit
        bluez-tools
        btrfs-assistant
        btrfs-progs
        bustle
        butt
        cameractrls-gtk4
        cava
        cdrkit
        celestia
        certbot
        clinfo
        cloc
        cmake
        cmake-language-server
        cmatrix
        code-nautilus
        codevis
        collision
        compose2nix
        cramfsprogs
        crow-translate
        cryptsetup
        ctop
        cups-printers
        curtail
        cve-bin-tool
        d-spy
        darktable
        dbeaver-bin
        dconf-editor
        dconf2nix
        diffoci
        diffsitter
        dig
        dive
        dmg2img
        dmidecode
        dnsrecon
        docker-buildx
        docker-client
        docker-compose
        docker-compose-language-service
        docker-credential-gcr
        docker-credential-helpers
        docker-gc
        docker-init
        docker-language-server
        docker-sbom
        dockerfile-language-server
        dosfstools
        e2fsprogs
        easyeda2kicad
        efibootmgr
        egypt
        elf-dissector
        eog
        esptool
        evtest-qt
        exfatprogs
        f2fs-tools
        fastfetch
        fd
        fdroidcl
        ffmpegthumbnailer
        fh
        file
        file-roller
        fileinfo
        filezilla
        flake-checker
        flare-floss
        flutter
        fontfor
        fritzing
        fstl
        fzf
        gcc15
        gdb
        ghex
        gimp3-with-plugins
        git-filter-repo
        git-repo
        github-changelog-generator
        gnirehtet
        gnome-characters
        gnome-clocks
        gnome-decoder
        gnome-firmware
        gnome-font-viewer
        gnome-frog
        gnome-graphs
        gnome-logs
        gnome-nettool
        gnugrep
        gnumake
        gnused
        gnutar
        gollama
        google-lighthouse
        gource
        gpredict
        gradle-completion
        groovy
        guestfs-tools
        gzip
        hashcat
        hashcat-utils
        hashes
        hdparm
        hfsprogs
        hieroglyphic
        host
        hugo
        hw-probe
        hydra-check
        hyprls
        hyprpwcenter
        i2c-tools
        iaito
        iftop
        indent
        inkscape-with-extensions
        inotify-tools
        input-leap
        iotop-c
        jfsutils
        jmol
        john
        johnny
        jq
        kernel-hardening-checker
        kernelshark
        killall
        kmod
        kotlin
        kotlin-language-server
        kubectl
        kubectl-graph
        kubectl-tree
        kubectl-view-secret
        kubernetes-helm
        kubeshark
        lazygit
        letterpress
        libnotify
        libreoffice-fresh
        libsecret
        libsixel
        libva-utils
        linux-exploit-suggester
        linuxConsoleTools
        logdy
        logtop
        lsb-release
        lshw
        lsof
        lsscsi
        lssecret
        lua
        lvm2
        lynis
        lyto
        lyx
        macchanger
        mailcap
        massdns
        md-lsp
        meld
        mermaid-cli
        mesa-demos
        metadata-cleaner
        metasploit
        mfcuk
        mfoc
        mtools
        mtr-gui
        nautilus
        nethogs
        nikto
        nilfs-utils
        ninja
        nix-diff
        nix-info
        nixd
        nixfmt
        nixpkgs-review
        nmap
        ntfs3g
        nvme-cli
        onionshare-gui
        open-interpreter
        openafs
        openai-whisper
        opendmarc
        openssl
        paper-clip
        pciutils
        pdfarranger
        pg_top
        pinta
        pkg-config
        platformio
        postgres-language-server
        procps
        profile-cleaner
        progress
        protonvpn-gui
        ps
        psmisc
        qalculate-gtk
        qemu-utils
        qr-backup
        radare2
        raider
        rclone
        rclone-ui
        reiserfsprogs
        ripgrep
        rpi-imager
        rpmextract
        rpPPPoE
        rtl-sdr-librtlsdr
        scrcpy
        screen
        sdrangel
        selectdefaultapplication
        serial-studio
        share-preview
        sherlock
        simple-scan
        sipvicious
        sleuthkit
        smartmontools
        sof-tools
        songrec
        sound-theme-freedesktop
        soundconverter
        sox
        sslscan
        stegseek
        subfinder
        subtitleedit
        switcheroo
        symlinks
        systemd-lsp
        szyszka
        telegram-desktop
        telegraph
        terminal-colors
        terminaltexteffects
        texliveFull
        time
        tpm2-tools
        traitor
        tree
        trufflehog
        trustymail
        udftools
        udiskie
        ugit
        undollar
        universal-android-debloater # uad-ng
        unix-privesc-check
        unzip
        upnp-router-control
        upscayl
        usbip-ssh
        usbutils
        util-linux
        valgrind
        video2x
        virt-top
        virt-v2v
        virtiofsd
        vscode-js-debug
        vulkan-caps-viewer
        vulkan-tools
        wafw00f
        wakeonlan
        waycheck
        waydroid-helper
        wayland-utils
        waylevel
        wayvnc
        webfontkitgenerator
        websocat
        wev
        whatfiles
        which
        whois
        winboat
        wl-clipboard
        wl-kbptr
        wordbook
        wpprobe
        wvkbd # wvkbd-mobintl
        x2goclient
        xdg-user-dirs
        xdg-utils
        xfsdump
        xfsprogs
        xoscope
        yaml-language-server
        yara-x
        zenity
        zenmap
        zfs
        zip
        (blender.override {
          colladaSupport = true;
          jackaudioSupport = true;
          openUsdSupport = true;
          spaceNavSupport = true;
          waylandSupport = true;
        })
        (coreutils-full.override {
          aclSupport = true;
          withOpenssl = true;
        })
        (curlFull.override {
          brotliSupport = true;
          c-aresSupport = true;
          gsaslSupport = true;
          gssSupport = true;
          http2Support = true;
          http3Support = true;
          websocketSupport = true;
          idnSupport = true;
          opensslSupport = true;
          pslSupport = true;
          rtmpSupport = true;
          scpSupport = true;
          zlibSupport = true;
          zstdSupport = true;
        })
        (
          (ffmpeg-full.override {
            withAlsa = true;
            withAom = true;
            withAribb24 = true;
            withAribcaption = true;
            withAss = true;
            withAvisynth = true;
            withBluray = true;
            withBs2b = true;
            withBzlib = true;
            withCaca = true;
            withCdio = true;
            withCelt = true;
            withChromaprint = true;
            withCodec2 = true;
            withDav1d = true;
            withDavs2 = true;
            withDc1394 = true;
            withDrm = true;
            withDvdnav = true;
            withDvdread = true;
            withFlite = true;
            withFontconfig = true;
            withFreetype = true;
            withFrei0r = true;
            withFribidi = true;
            withGme = true;
            withGnutls = true;
            withGsm = true;
            withHarfbuzz = true;
            withIconv = true;
            withIlbc = true;
            withJack = true;
            withJxl = true;
            withKvazaar = true;
            withLadspa = true;
            withLc3 = true;
            withLcevcdec = true;
            withLcms2 = true;
            withLzma = true;
            withModplug = true;
            withMp3lame = true;
            withMysofa = true;
            withOpenal = true;
            withOpencl = true;
            withOpencoreAmrnb = true;
            withOpencoreAmrwb = true;
            withOpengl = true;
            withOpenh264 = true;
            withOpenjpeg = true;
            withOpenmpt = true;
            withOpus = true;
            withPlacebo = true;
            withPulse = true;
            withQrencode = true;
            withQuirc = true;
            withRav1e = true;
            withRist = true;
            withRtmp = true;
            withRubberband = true;
            withSamba = true;
            withSdl2 = true;
            withShaderc = true;
            withShine = true;
            withSnappy = true;
            withSoxr = true;
            withSpeex = true;
            withSrt = true;
            withSsh = true;
            withSvg = true;
            withSvtav1 = true;
            withTheora = true;
            withTwolame = true;
            withUavs3d = true;
            withV4l2 = true;
            withV4l2M2m = true;
            withVaapi = true;
            withVdpau = true;
            withVidStab = true;
            withVmaf = true;
            withVoAmrwbenc = true;
            withVorbis = true;
            withVpx = true;
            withVulkan = true;
            withVvenc = true;
            withWebp = true;
            withX264 = true;
            withX265 = true;
            withXavs = true;
            withXavs2 = true;
            withXevd = true;
            withXeve = true;
            withXml2 = true;
            withXvid = true;
            withZimg = true;
            withZlib = true;
            withZmq = true;
            withZvbi = true;

            withUnfree = false;

            withGrayscale = true;
            withSwscaleAlpha = true;
            withMultithread = true;
            withNetwork = true;
          }).overrideAttrs
          (_: {
            doCheck = false;
          })
        )
        (gnss-sdr.override {
          enableRawUdp = true;
          enableOsmosdr = true;
        })
        (hardinfo2.override {
          printingSupport = true;
        })
        (kicad-testing.override {
          addons = with pkgs.kicadAddons; [
            kikit
            kikit-library
          ];
          withNgspice = true;
          withScripting = true;
          with3d = true;
          withI18n = true;
        })
        (python315FreeThreading.override {
          bluezSupport = true;
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
        (qbittorrent.override {
          guiSupport = true;
          trackerSearch = true;
          webuiSupport = false;
        })
        (sdrpp.override {
          airspy_source = true;
          airspyhf_source = true;
          bladerf_source = true;
          file_source = true;
          hackrf_source = true;
          limesdr_source = true;
          plutosdr_source = true;
          rfspace_source = true;
          rtl_sdr_source = true;
          rtl_tcp_source = true;
          soapy_source = true;
          spyserver_source = true;
          usrp_source = true;

          audio_sink = true;
          network_sink = true;
          portaudio_sink = true;

          m17_decoder = true;
          meteor_demodulator = true;

          frequency_manager = true;
          recorder = true;
          rigctl_server = true;
          scanner = true;
        })
        (tor-browser.override {
          libnotifySupport = true;
          waylandSupport = true;
          mediaSupport = true;
          audioSupport = true;
          pipewireSupport = true;
          pulseaudioSupport = true;
          libvaSupport = true;
        })
        (tree-sitter.override {
          # webUISupport = true; # FIXME: Build Failure
        })
        (virt-viewer.override {
          spiceSupport = true;
        })
        (vlc.override {
          chromecastSupport = true;
          jackSupport = true;
          skins2Support = true;
          waylandSupport = true;
        })
        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })
        config.services.phpfpm.phpPackage
      ]
      ++ config.boot.extraModulePackages
      # ++ (with ghidra-extensions; [
      #   findcrypt
      #   ghidra-delinker-extension
      #   ghidra-golanganalyzerextension
      #   ghidraninja-ghidra-scripts
      #   gnudisassembler
      #   lightkeeper
      #   machinelearning
      #   ret-sync
      #   sleighdevtools
      #   wasm
      # ]) # FIXME: Build Failure
      ++ (with gst_all_1; [
        (gst-libav.override {
          enableDocumentation = true;
        })
        (gst-plugins-bad.override {
          enableZbar = true;
          opencvSupport = true;
          ldacbtSupport = true;
          webrtcAudioProcessingSupport = true;
          ajaSupport = true;
          openh264Support = true;
          enableGplPlugins = true;
          bluezSupport = true;
          microdnsSupport = true;
          enableDocumentation = true;
          guiSupport = true;
        })
        (gst-plugins-base.override {
          enableWayland = true;
          enableAlsa = true;
          enableCdparanoia = true;
          enableDocumentation = true;
        })
        (gst-plugins-good.override {
          gtkSupport = true;
          qt6Support = true;
          enableJack = true;
          enableWayland = true;
          enableDocumentation = true;
        })
        (gst-plugins-ugly.override {
          enableGplPlugins = true;
          enableDocumentation = true;
        })
        (gst-vaapi.override {
          enableDocumentation = true;
        })
        (gstreamer.override {
          enableDocumentation = true;
        })
      ])
      ++ (with texlivePackages; [
        latexmk
      ])
      ++ (with tree-sitter-grammars; [
        tree-sitter-bash
        tree-sitter-bibtex
        tree-sitter-c
        tree-sitter-cmake
        tree-sitter-comment
        tree-sitter-cpp
        tree-sitter-css
        tree-sitter-dart
        tree-sitter-dockerfile
        tree-sitter-embedded-template
        tree-sitter-html
        tree-sitter-http
        tree-sitter-hyprlang
        tree-sitter-javascript
        tree-sitter-json
        tree-sitter-json5
        tree-sitter-kotlin
        tree-sitter-latex
        tree-sitter-lua
        tree-sitter-make
        tree-sitter-markdown
        tree-sitter-markdown-inline
        tree-sitter-nix
        tree-sitter-php
        tree-sitter-python
        tree-sitter-query
        tree-sitter-regex
        tree-sitter-scheme
        tree-sitter-sql
        tree-sitter-todotxt
        tree-sitter-toml
        tree-sitter-vim
        tree-sitter-yaml
      ])
      ++ (with unixtools; [
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
      ++ (with vimPlugins; [
        LazyVim
        nvim-treesitter
        nvim-treesitter-context
        nvim-treesitter-pairs
        nvim-treesitter-refactor
        nvim-treesitter-textobjects
        nvim-treesitter-textsubjects
      ])
      ++ (with vimPlugins.nvim-treesitter-parsers; [
        # jsonc # FIXME: Build Failure
        # robots # FIXME: Build Failure
        arduino
        asm
        bash
        bibtex
        c
        cmake
        comment
        cpp
        css
        csv
        dart
        desktop
        diff
        disassembly
        dockerfile
        dtd
        embedded_template
        git_config
        git_rebase
        gitattributes
        gitcommit
        gitignore
        gpg
        groovy
        hjson
        hlsplaylist
        html
        hyprlang
        ini
        java
        javascript
        jq
        json
        json5
        kotlin
        latex
        lua
        make
        markdown
        markdown_inline
        mermaid
        nginx
        nix
        passwd
        php
        phpdoc
        printf
        properties
        python
        query
        readline
        regex
        requirements
        scheme
        sql
        ssh_config
        todotxt
        toml
        udev
        vim
        vimdoc
        xml
        yaml
      ]);
  };

  xdg = {
    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      # removedAssociations = { };

      # https://www.iana.org/assignments/media-types/media-types.xhtml
      defaultApplications = {
        "inode/directory" = "nautilus.desktop";

        "image/aces" = "org.gnome.eog.desktop";
        "image/apng" = "org.gnome.eog.desktop";
        "image/avci" = "org.gnome.eog.desktop";
        "image/avcs" = "org.gnome.eog.desktop";
        "image/avif" = "org.gnome.eog.desktop";
        "image/bmp" = "org.gnome.eog.desktop";
        "image/cgm" = "org.gnome.eog.desktop";
        "image/dicom-rle" = "org.gnome.eog.desktop";
        "image/dpx" = "org.gnome.eog.desktop";
        "image/emf" = "org.gnome.eog.desktop";
        "image/fits" = "org.gnome.eog.desktop";
        "image/g3fax" = "org.gnome.eog.desktop";
        "image/gif" = "org.gnome.eog.desktop";
        "image/heic-sequence" = "org.gnome.eog.desktop";
        "image/heic" = "org.gnome.eog.desktop";
        "image/heif-sequence" = "org.gnome.eog.desktop";
        "image/heif" = "org.gnome.eog.desktop";
        "image/hej2k" = "org.gnome.eog.desktop";
        "image/hsj2" = "org.gnome.eog.desktop";
        "image/ief" = "org.gnome.eog.desktop";
        "image/j2c" = "org.gnome.eog.desktop";
        "image/jaii" = "org.gnome.eog.desktop";
        "image/jais" = "org.gnome.eog.desktop";
        "image/jls" = "org.gnome.eog.desktop";
        "image/jp2" = "org.gnome.eog.desktop";
        "image/jpeg" = "org.gnome.eog.desktop";
        "image/jph" = "org.gnome.eog.desktop";
        "image/jphc" = "org.gnome.eog.desktop";
        "image/jpm" = "org.gnome.eog.desktop";
        "image/jpx" = "org.gnome.eog.desktop";
        "image/jxl" = "org.gnome.eog.desktop";
        "image/jxr" = "org.gnome.eog.desktop";
        "image/jxrA" = "org.gnome.eog.desktop";
        "image/jxrS" = "org.gnome.eog.desktop";
        "image/jxs" = "org.gnome.eog.desktop";
        "image/jxsc" = "org.gnome.eog.desktop";
        "image/jxsi" = "org.gnome.eog.desktop";
        "image/jxss" = "org.gnome.eog.desktop";
        "image/ktx" = "org.gnome.eog.desktop";
        "image/ktx2" = "org.gnome.eog.desktop";
        "image/naplps" = "org.gnome.eog.desktop";
        "image/png" = "org.gnome.eog.desktop";
        "image/prs.btif" = "org.gnome.eog.desktop";
        "image/prs.pti" = "org.gnome.eog.desktop";
        "image/pwg-raster" = "org.gnome.eog.desktop";
        "image/svg+xml" = "org.gnome.eog.desktop";
        "image/t38" = "org.gnome.eog.desktop";
        "image/tiff-fx" = "org.gnome.eog.desktop";
        "image/tiff" = "org.gnome.eog.desktop";
        "image/vnd.adobe.photoshop" = "org.gnome.eog.desktop";
        "image/vnd.airzip.accelerator.azv" = "org.gnome.eog.desktop";
        "image/vnd.cns.inf2" = "org.gnome.eog.desktop";
        "image/vnd.dece.graphic" = "org.gnome.eog.desktop";
        "image/vnd.djvu" = "org.gnome.eog.desktop";
        "image/vnd.dvb.subtitle" = "org.gnome.eog.desktop";
        "image/vnd.dwg" = "org.gnome.eog.desktop";
        "image/vnd.dxf" = "org.gnome.eog.desktop";
        "image/vnd.fastbidsheet" = "org.gnome.eog.desktop";
        "image/vnd.fpx" = "org.gnome.eog.desktop";
        "image/vnd.fst" = "org.gnome.eog.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "org.gnome.eog.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "org.gnome.eog.desktop";
        "image/vnd.globalgraphics.pgb" = "org.gnome.eog.desktop";
        "image/vnd.microsoft.icon" = "org.gnome.eog.desktop";
        "image/vnd.mix" = "org.gnome.eog.desktop";
        "image/vnd.mozilla.apng" = "org.gnome.eog.desktop";
        "image/vnd.ms-modi" = "org.gnome.eog.desktop";
        "image/vnd.net-fpx" = "org.gnome.eog.desktop";
        "image/vnd.pco.b16" = "org.gnome.eog.desktop";
        "image/vnd.radiance" = "org.gnome.eog.desktop";
        "image/vnd.sealed.png" = "org.gnome.eog.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "org.gnome.eog.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "org.gnome.eog.desktop";
        "image/vnd.svf" = "org.gnome.eog.desktop";
        "image/vnd.tencent.tap" = "org.gnome.eog.desktop";
        "image/vnd.valve.source.texture" = "org.gnome.eog.desktop";
        "image/vnd.wap.wbmp" = "org.gnome.eog.desktop";
        "image/vnd.xiff" = "org.gnome.eog.desktop";
        "image/vnd.zbrush.pcx" = "org.gnome.eog.desktop";
        "image/webp" = "org.gnome.eog.desktop";
        "image/wmf" = "org.gnome.eog.desktop";

        "audio/1d-interleaved-parityfec" = "vlc.desktop";
        "audio/32kadpcm" = "vlc.desktop";
        "audio/3gpp" = "vlc.desktop";
        "audio/3gpp2" = "vlc.desktop";
        "audio/aac" = "vlc.desktop";
        "audio/ac3" = "vlc.desktop";
        "audio/AMR-WB" = "vlc.desktop";
        "audio/amr-wb+" = "vlc.desktop";
        "audio/AMR" = "vlc.desktop";
        "audio/aptx" = "vlc.desktop";
        "audio/asc" = "vlc.desktop";
        "audio/ATRAC-ADVANCED-LOSSLESS" = "vlc.desktop";
        "audio/ATRAC-X" = "vlc.desktop";
        "audio/ATRAC3" = "vlc.desktop";
        "audio/basic" = "vlc.desktop";
        "audio/BV16" = "vlc.desktop";
        "audio/BV32" = "vlc.desktop";
        "audio/clearmode" = "vlc.desktop";
        "audio/CN" = "vlc.desktop";
        "audio/DAT12" = "vlc.desktop";
        "audio/dls" = "vlc.desktop";
        "audio/dsr-es201108" = "vlc.desktop";
        "audio/dsr-es202050" = "vlc.desktop";
        "audio/dsr-es202211" = "vlc.desktop";
        "audio/dsr-es202212" = "vlc.desktop";
        "audio/DV" = "vlc.desktop";
        "audio/DVI4" = "vlc.desktop";
        "audio/eac3" = "vlc.desktop";
        "audio/encaprtp" = "vlc.desktop";
        "audio/EVRC-QCP" = "vlc.desktop";
        "audio/EVRC" = "vlc.desktop";
        "audio/EVRC0" = "vlc.desktop";
        "audio/EVRC1" = "vlc.desktop";
        "audio/EVRCB" = "vlc.desktop";
        "audio/EVRCB0" = "vlc.desktop";
        "audio/EVRCB1" = "vlc.desktop";
        "audio/EVRCNW" = "vlc.desktop";
        "audio/EVRCNW0" = "vlc.desktop";
        "audio/EVRCNW1" = "vlc.desktop";
        "audio/EVRCWB" = "vlc.desktop";
        "audio/EVRCWB0" = "vlc.desktop";
        "audio/EVRCWB1" = "vlc.desktop";
        "audio/EVS" = "vlc.desktop";
        "audio/flac" = "vlc.desktop";
        "audio/flexfec" = "vlc.desktop";
        "audio/fwdred" = "vlc.desktop";
        "audio/G711-0" = "vlc.desktop";
        "audio/G719" = "vlc.desktop";
        "audio/G722" = "vlc.desktop";
        "audio/G7221" = "vlc.desktop";
        "audio/G723" = "vlc.desktop";
        "audio/G726-16" = "vlc.desktop";
        "audio/G726-24" = "vlc.desktop";
        "audio/G726-32" = "vlc.desktop";
        "audio/G726-40" = "vlc.desktop";
        "audio/G728" = "vlc.desktop";
        "audio/G729" = "vlc.desktop";
        "audio/G7291" = "vlc.desktop";
        "audio/G729D" = "vlc.desktop";
        "audio/G729E" = "vlc.desktop";
        "audio/GSM-EFR" = "vlc.desktop";
        "audio/GSM-HR-08" = "vlc.desktop";
        "audio/GSM" = "vlc.desktop";
        "audio/iLBC" = "vlc.desktop";
        "audio/ip-mr_v2.5" = "vlc.desktop";
        "audio/L16" = "vlc.desktop";
        "audio/L20" = "vlc.desktop";
        "audio/L24" = "vlc.desktop";
        "audio/L8" = "vlc.desktop";
        "audio/LPC" = "vlc.desktop";
        "audio/matroska" = "vlc.desktop";
        "audio/MELP" = "vlc.desktop";
        "audio/MELP1200" = "vlc.desktop";
        "audio/MELP2400" = "vlc.desktop";
        "audio/MELP600" = "vlc.desktop";
        "audio/mhas" = "vlc.desktop";
        "audio/midi-clip" = "vlc.desktop";
        "audio/mobile-xmf" = "vlc.desktop";
        "audio/mp4" = "vlc.desktop";
        "audio/MP4A-LATM" = "vlc.desktop";
        "audio/mpa-robust" = "vlc.desktop";
        "audio/MPA" = "vlc.desktop";
        "audio/mpeg" = "vlc.desktop";
        "audio/mpeg4-generic" = "vlc.desktop";
        "audio/ogg" = "vlc.desktop";
        "audio/opus" = "vlc.desktop";
        "audio/parityfec" = "vlc.desktop";
        "audio/PCMA-WB" = "vlc.desktop";
        "audio/PCMA" = "vlc.desktop";
        "audio/PCMU-WB" = "vlc.desktop";
        "audio/PCMU" = "vlc.desktop";
        "audio/prs.sid" = "vlc.desktop";
        "audio/QCELP" = "vlc.desktop";
        "audio/raptorfec" = "vlc.desktop";
        "audio/RED" = "vlc.desktop";
        "audio/rtp-enc-aescm128" = "vlc.desktop";
        "audio/rtp-midi" = "vlc.desktop";
        "audio/rtploopback" = "vlc.desktop";
        "audio/rtx" = "vlc.desktop";
        "audio/scip" = "vlc.desktop";
        "audio/SMV-QCP" = "vlc.desktop";
        "audio/SMV" = "vlc.desktop";
        "audio/SMV0" = "vlc.desktop";
        "audio/sofa" = "vlc.desktop";
        "audio/sp-midi" = "vlc.desktop";
        "audio/speex" = "vlc.desktop";
        "audio/t140c" = "vlc.desktop";
        "audio/t38" = "vlc.desktop";
        "audio/telephone-event" = "vlc.desktop";
        "audio/TETRA_ACELP_BB" = "vlc.desktop";
        "audio/TETRA_ACELP" = "vlc.desktop";
        "audio/tone" = "vlc.desktop";
        "audio/TSVCIS" = "vlc.desktop";
        "audio/UEMCLIP" = "vlc.desktop";
        "audio/ulpfec" = "vlc.desktop";
        "audio/usac" = "vlc.desktop";
        "audio/VDVI" = "vlc.desktop";
        "audio/VMR-WB" = "vlc.desktop";
        "audio/vnd.3gpp.iufp" = "vlc.desktop";
        "audio/vnd.4SB" = "vlc.desktop";
        "audio/vnd.audiokoz" = "vlc.desktop";
        "audio/vnd.CELP" = "vlc.desktop";
        "audio/vnd.cisco.nse" = "vlc.desktop";
        "audio/vnd.cmles.radio-events" = "vlc.desktop";
        "audio/vnd.cns.anp1" = "vlc.desktop";
        "audio/vnd.cns.inf1" = "vlc.desktop";
        "audio/vnd.dece.audio" = "vlc.desktop";
        "audio/vnd.digital-winds" = "vlc.desktop";
        "audio/vnd.dlna.adts" = "vlc.desktop";
        "audio/vnd.dolby.heaac.1" = "vlc.desktop";
        "audio/vnd.dolby.heaac.2" = "vlc.desktop";
        "audio/vnd.dolby.mlp" = "vlc.desktop";
        "audio/vnd.dolby.mps" = "vlc.desktop";
        "audio/vnd.dolby.pl2" = "vlc.desktop";
        "audio/vnd.dolby.pl2x" = "vlc.desktop";
        "audio/vnd.dolby.pl2z" = "vlc.desktop";
        "audio/vnd.dolby.pulse.1" = "vlc.desktop";
        "audio/vnd.dra" = "vlc.desktop";
        "audio/vnd.dts.hd" = "vlc.desktop";
        "audio/vnd.dts.uhd" = "vlc.desktop";
        "audio/vnd.dts" = "vlc.desktop";
        "audio/vnd.dvb.file" = "vlc.desktop";
        "audio/vnd.everad.plj" = "vlc.desktop";
        "audio/vnd.hns.audio" = "vlc.desktop";
        "audio/vnd.lucent.voice" = "vlc.desktop";
        "audio/vnd.ms-playready.media.pya" = "vlc.desktop";
        "audio/vnd.nokia.mobile-xmf" = "vlc.desktop";
        "audio/vnd.nortel.vbk" = "vlc.desktop";
        "audio/vnd.nuera.ecelp4800" = "vlc.desktop";
        "audio/vnd.nuera.ecelp7470" = "vlc.desktop";
        "audio/vnd.nuera.ecelp9600" = "vlc.desktop";
        "audio/vnd.octel.sbc" = "vlc.desktop";
        "audio/vnd.presonus.multitrack" = "vlc.desktop";
        "audio/vnd.rhetorex.32kadpcm" = "vlc.desktop";
        "audio/vnd.rip" = "vlc.desktop";
        "audio/vnd.sealedmedia.softseal.mpeg" = "vlc.desktop";
        "audio/vnd.vmx.cvsd" = "vlc.desktop";
        "audio/vorbis-config" = "vlc.desktop";
        "audio/vorbis" = "vlc.desktop";

        "video/1d-interleaved-parityfec" = "vlc.desktop";
        "video/3gpp-tt" = "vlc.desktop";
        "video/3gpp" = "vlc.desktop";
        "video/3gpp2" = "vlc.desktop";
        "video/AV1" = "vlc.desktop";
        "video/BMPEG" = "vlc.desktop";
        "video/BT656" = "vlc.desktop";
        "video/CelB" = "vlc.desktop";
        "video/DV" = "vlc.desktop";
        "video/encaprtp" = "vlc.desktop";
        "video/evc" = "vlc.desktop";
        "video/FFV1" = "vlc.desktop";
        "video/flexfec" = "vlc.desktop";
        "video/H261" = "vlc.desktop";
        "video/H263-1998" = "vlc.desktop";
        "video/H263-2000" = "vlc.desktop";
        "video/H263" = "vlc.desktop";
        "video/H264-RCDO" = "vlc.desktop";
        "video/H264-SVC" = "vlc.desktop";
        "video/H264" = "vlc.desktop";
        "video/H265" = "vlc.desktop";
        "video/H266" = "vlc.desktop";
        "video/iso.segment" = "vlc.desktop";
        "video/JPEG" = "vlc.desktop";
        "video/jpeg2000" = "vlc.desktop";
        "video/jxsv" = "vlc.desktop";
        "video/matroska-3d" = "vlc.desktop";
        "video/matroska" = "vlc.desktop";
        "video/mj2" = "vlc.desktop";
        "video/MP1S" = "vlc.desktop";
        "video/MP2P" = "vlc.desktop";
        "video/MP2T" = "vlc.desktop";
        "video/mp4" = "vlc.desktop";
        "video/MP4V-ES" = "vlc.desktop";
        "video/mpeg" = "vlc.desktop";
        "video/mpeg4-generic" = "vlc.desktop";
        "video/MPV" = "vlc.desktop";
        "video/nv" = "vlc.desktop";
        "video/ogg" = "vlc.desktop";
        "video/parityfec" = "vlc.desktop";
        "video/pointer" = "vlc.desktop";
        "video/quicktime" = "vlc.desktop";
        "video/raptorfec" = "vlc.desktop";
        "video/raw" = "vlc.desktop";
        "video/rtp-enc-aescm128" = "vlc.desktop";
        "video/rtploopback" = "vlc.desktop";
        "video/rtx" = "vlc.desktop";
        "video/scip" = "vlc.desktop";
        "video/smpte291" = "vlc.desktop";
        "video/SMPTE292M" = "vlc.desktop";
        "video/ulpfec" = "vlc.desktop";
        "video/vc1" = "vlc.desktop";
        "video/vc2" = "vlc.desktop";
        "video/vnd.CCTV" = "vlc.desktop";
        "video/vnd.dece.hd" = "vlc.desktop";
        "video/vnd.dece.mobile" = "vlc.desktop";
        "video/vnd.dece.mp4" = "vlc.desktop";
        "video/vnd.dece.pd" = "vlc.desktop";
        "video/vnd.dece.sd" = "vlc.desktop";
        "video/vnd.dece.video" = "vlc.desktop";
        "video/vnd.directv.mpeg-tts" = "vlc.desktop";
        "video/vnd.directv.mpeg" = "vlc.desktop";
        "video/vnd.dlna.mpeg-tts" = "vlc.desktop";
        "video/vnd.dvb.file" = "vlc.desktop";
        "video/vnd.fvt" = "vlc.desktop";
        "video/vnd.hns.video" = "vlc.desktop";
        "video/vnd.iptvforum.1dparityfec-1010" = "vlc.desktop";
        "video/vnd.iptvforum.1dparityfec-2005" = "vlc.desktop";
        "video/vnd.iptvforum.2dparityfec-1010" = "vlc.desktop";
        "video/vnd.iptvforum.2dparityfec-2005" = "vlc.desktop";
        "video/vnd.iptvforum.ttsavc" = "vlc.desktop";
        "video/vnd.iptvforum.ttsmpeg2" = "vlc.desktop";
        "video/vnd.motorola.video" = "vlc.desktop";
        "video/vnd.motorola.videop" = "vlc.desktop";
        "video/vnd.mpegurl" = "vlc.desktop";
        "video/vnd.ms-playready.media.pyv" = "vlc.desktop";
        "video/vnd.nokia.interleaved-multimedia" = "vlc.desktop";
        "video/vnd.nokia.mp4vr" = "vlc.desktop";
        "video/vnd.nokia.videovoip" = "vlc.desktop";
        "video/vnd.objectvideo" = "vlc.desktop";
        "video/vnd.radgamettools.bink" = "vlc.desktop";
        "video/vnd.radgamettools.smacker" = "vlc.desktop";
        "video/vnd.sealed.mpeg1" = "vlc.desktop";
        "video/vnd.sealed.mpeg4" = "vlc.desktop";
        "video/vnd.sealed.swf" = "vlc.desktop";
        "video/vnd.sealedmedia.softseal.mov" = "vlc.desktop";
        "video/vnd.uvvu.mp4" = "vlc.desktop";
        "video/vnd.vivo" = "vlc.desktop";
        "video/vnd.youtube.yt" = "vlc.desktop";
        "video/VP8" = "vlc.desktop";
        "video/VP9" = "vlc.desktop";
        "video/x-matroska" = "vlc.desktop"; # https://mime.wcode.net/mkv

        "application/vnd.oasis.opendocument.text" = "writer.desktop"; # .odt
        "application/msword" = "writer.desktop"; # .doc
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop"; # .docx
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = "writer.desktop"; # .dotx

        "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop"; # .ods
        "application/vnd.ms-excel" = "calc.desktop"; # .xls
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop"; # .xlsx
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = "calc.desktop"; # .xltx

        "application/vnd.oasis.opendocument.presentation" = "impress.desktop"; # .odp
        "application/vnd.ms-powerpoint" = "impress.desktop"; # .ppt
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop"; # .pptx
        "application/vnd.openxmlformats-officedocument.presentationml.template" = "impress.desktop"; # .potx

        "application/pdf" = "firefox-devedition.desktop";

        "font/collection" = "org.gnome.font-viewer.desktop";
        "font/otf" = "org.gnome.font-viewer.desktop";
        "font/sfnt" = "org.gnome.font-viewer.desktop";
        "font/ttf" = "org.gnome.font-viewer.desktop";
        "font/woff" = "org.gnome.font-viewer.desktop";
        "font/woff2" = "org.gnome.font-viewer.desktop";

        "application/gzip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-arj" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gtar" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed " = "org.gnome.FileRoller.desktop"; # More common than "application/vnd.rar"
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";

        "x-scheme-handler/http" = "firefox-devedition.desktop";
        "x-scheme-handler/https" = "firefox-devedition.desktop";

        "x-scheme-handler/mailto" = "thunderbird.desktop";
      };
    };

    icons.enable = true;
    sounds.enable = true;

    menus.enable = true;
    autostart.enable = true;

    terminal-exec.enable = true;

    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
      ];

      xdgOpenUsePortal = false; # Opening Programs

      config = {
        common = {
          default = [
            "gtk"
            "hyprland"
          ];

          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };
      };
    };
  };

  gtk.iconCache.enable = true;

  qt = {
    enable = true;
    platformTheme = "qt5ct"; # Includes qt6ct
  };

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

      generateCaches = true;
    };

    nixos = {
      enable = true;
      includeAllModules = true;
      options.warningsAreErrors = false;
    };
  };

  users = {
    groups = {
      hardinfo2 = { };
    };

    enforceIdUniqueness = true;
    mutableUsers = true;

    defaultUserShell = pkgs.bash;

    motd = "Welcome";

    users.bitscoper = {
      isNormalUser = true;

      name = "bitscoper";
      description = "Abdullah As-Sadeed"; # Full Name

      # extraGroups = builtins.attrNames config.users.groups; # Risky and Logs Out

      extraGroups = [
        "adbusers" # Not in builtins.attrNames config.users.groups
        "adm"
        "audio"
        "avahi"
        "cdrom"
        "dialout"
        "docker"
        "floppy"
        "fwupd-refresh"
        "greeter"
        "hardinfo2"
        "i2c"
        "input"
        "jellyfin"
        "kvm"
        "libvirtd"
        "lp"
        "lpadmin"
        "networkmanager"
        "nm-openvpn"
        "pipewire"
        "plugdev"
        "qemu-libvirtd"
        "render"
        "scanner"
        "systemd-journal"
        "tape"
        "tty"
        "users"
        "uucp"
        "video"
        "wheel"
        "wireshark"
      ];

      useDefaultShell = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "old";

    sharedModules = [
      {
        home = {
          enableNixpkgsReleaseCheck = true;

          shell = {
            enableShellIntegration = true;
            enableBashIntegration = true;
          };

          pointerCursor = {
            name = cursor.theme.name;
            package = cursor.theme.package;
            size = cursor.size;

            hyprcursor = {
              enable = true;
              size = cursor.size;
            };

            gtk.enable = true;
          };

          preferXdgDirectories = true;

          # sessionSearchVariables = { };

          enableDebugInfo = false;

          stateVersion = "26.05";
        };

        wayland.windowManager.hyprland = {
          enable = true;
          package = (
            pkgs.hyprland.override {
              enableXWayland = true;
              wrapRuntimeDeps = true;
            }
          );

          systemd = {
            enable = false;
            enableXdgAutostart = true;

            variables = [
              "--all"
            ];
          };

          plugins = with pkgs.hyprlandPlugins; [
            # hypr-dynamic-cursors # FIXME: Build Failure
          ];

          xwayland.enable = true;

          sourceFirst = true;

          settings = {
            env = [
              "XCURSOR_SIZE, ${toString cursor.size}"
            ];

            monitor = [
              # Name, Resolution, Position, Scale, Transform-Parameter, Transform
              ", highres, auto, 1, transform, 0"
              "eDP-1, highres, auto, 1, transform, 0"
              "HDMI-A-1, highres, auto, 1, transform, 1"
            ];

            exec-once = [
              "adb start-server"

              "setfacl --modify user:jellyfin:--x ~"
              "rm -rf ~/.local/share/applications/waydroid.*"
            ];

            bind = [
              "SUPER, I, exec, dms ipc call keybinds toggle hyprland"

              "SUPER, L, exec, loginctl lock-session" # dms ipc call lock lock
              "SUPER CTRL, I, exec, dms ipc call inhibit toggle"
              "SUPER CTRL, P, exec, dms ipc call powermenu toggle"

              "SUPER, O, exec, dms ipc call hypr toggleOverview"

              "SUPER, 1, workspace, 1"
              "SUPER, 2, workspace, 2"
              "SUPER, 3, workspace, 3"
              "SUPER, 4, workspace, 4"
              "SUPER, 5, workspace, 5"
              "SUPER, 6, workspace, 6"
              "SUPER, 7, workspace, 7"
              "SUPER, 8, workspace, 8"
              "SUPER, 9, workspace, 9"
              "SUPER, 0, workspace, 10"
              "SUPER, mouse_down, workspace, e+1"
              "SUPER, mouse_up, workspace, e-1"
              "SUPER, S, togglespecialworkspace, magic"

              "SUPER, left, movefocus, l"
              "SUPER, right, movefocus, r"
              "SUPER, up, movefocus, u"
              "SUPER, down, movefocus, d"

              "SUPER SHIFT, 1, movetoworkspace, 1"
              "SUPER SHIFT, 2, movetoworkspace, 2"
              "SUPER SHIFT, 3, movetoworkspace, 3"
              "SUPER SHIFT, 4, movetoworkspace, 4"
              "SUPER SHIFT, 5, movetoworkspace, 5"
              "SUPER SHIFT, 6, movetoworkspace, 6"
              "SUPER SHIFT, 7, movetoworkspace, 7"
              "SUPER SHIFT, 8, movetoworkspace, 8"
              "SUPER SHIFT, 9, movetoworkspace, 9"
              "SUPER SHIFT, 0, movetoworkspace, 10"
              "SUPER SHIFT, S, movetoworkspace, special:magic"
              "SUPER SHIFT ALT, 1, movetoworkspacesilent, 1"
              "SUPER SHIFT ALT, 2, movetoworkspacesilent, 2"
              "SUPER SHIFT ALT, 3, movetoworkspacesilent, 3"
              "SUPER SHIFT ALT, 4, movetoworkspacesilent, 4"
              "SUPER SHIFT ALT, 5, movetoworkspacesilent, 5"
              "SUPER SHIFT ALT, 6, movetoworkspacesilent, 6"
              "SUPER SHIFT ALT, 7, movetoworkspacesilent, 7"
              "SUPER SHIFT ALT, 8, movetoworkspacesilent, 8"
              "SUPER SHIFT ALT, 9, movetoworkspacesilent, 9"
              "SUPER SHIFT ALT, 0, movetoworkspacesilent, 10"
              "SUPER SHIFT ALT, S, movetoworkspacesilent, special:magic"

              "SUPER SHIFT, T, togglesplit,"
              "SUPER SHIFT, F, togglefloating,"
              ", F11, fullscreen, 0"
              "SUPER, Q, killactive,"

              ", PRINT, exec, dms screenshot region --cursor --format=png"

              "SUPER, A, exec, dms ipc call spotlight toggle"
              "SUPER, R, exec, uwsm app -- wofi --show run --disable-history | xargs -r uwsm app --"

              "SUPER, C, exec, dms ipc call clipboard toggle"

              "SUPER, N, exec, dms ipc call notifications open"

              "SUPER, T, exec, uwsm app -- foot"

              ", XF86Explorer, exec, uwsm app -- nautilus"
              "SUPER, F, exec, uwsm app -- nautilus"
              "SUPER ALT, F, exec, dms ipc call spotlight toggleQuery \"/\""

              "SUPER, K, exec, uwsm app -- keepassxc"
              "SUPER ALT, K, exec, uwsm app -- keepassxc --lock"

              "SUPER, U, exec, dms ipc call processlist open"

              "SUPER, W, exec, uwsm app -- firefox-devedition"
              "SUPER ALT, W, exec, uwsm app -- firefox-devedition --private-window"

              ", XF86Mail, exec, uwsm app -- thunderbird"
              "SUPER, M, exec, uwsm app -- thunderbird"

              "SUPER, E, exec, uwsm app -- codium"

              "SUPER, D, exec, uwsm app -- dbeaver"

              "SUPER, P, exec, uwsm app -- scrcpy --render-driver=opengl"

              "SUPER, V, exec, uwsm app -- vlc"
            ];

            bindm = [
              "SUPER, mouse:272, movewindow"
              "SUPER, mouse:273, resizewindow"
            ]; # Mouse

            bindl = [
              ", XF86AudioPlay, exec, dms ipc call mpris playPause"
              ", XF86AudioPause, exec, dms ipc call mpris playPause"
              ", XF86AudioStop, exec, dms ipc call mpris stop"
              ", XF86AudioPrev, exec, dms ipc call mpris previous"
              ", XF86AudioNext, exec, dms ipc call mpris next"

              ", XF86AudioMute, exec, dms ipc call audio mute"
              ", XF86AudioMicMute, exec, dms ipc call audio micmute"
            ]; # Will also work when locked

            bindel = [
              ", XF86MonBrightnessUp, exec, dms ipc call brightness increment 1 \"\""
              ", XF86MonBrightnessDown, exec, dms ipc call brightness decrement 1 \"\""

              ", XF86AudioRaiseVolume, exec, dms ipc call audio increment 1"
              ", XF86AudioLowerVolume, exec, dms ipc call audio decrement 1"
            ]; # Repeat and will work when locked

            general = {
              allow_tearing = false;

              gaps_workspaces = 0;

              layout = "dwindle";

              gaps_in = 2;
              gaps_out = "2, 0, 0, 0"; # Top, Right, Bottom, Left

              border_size = 0;

              no_focus_fallback = false;

              resize_on_border = true;
              hover_icon_on_border = true;

              snap = {
                enabled = true;
                border_overlap = false;
              };
            };

            ecosystem = {
              no_update_news = false;
            };

            misc = {
              disable_autoreload = false;

              allow_session_lock_restore = true;

              key_press_enables_dpms = true;
              mouse_move_enables_dpms = true;

              vfr = true;
              vrr = 1;

              mouse_move_focuses_monitor = true;

              disable_hyprland_logo = true;
              force_default_wallpaper = 1;
              disable_splash_rendering = true;

              font_family = font_preferences.name.sans_serif;

              close_special_on_empty = true;

              animate_mouse_windowdragging = false;
              animate_manual_resizes = false;

              exit_window_retains_fullscreen = false;

              layers_hog_keyboard_focus = true;

              focus_on_activate = false;

              middle_click_paste = true;
            };

            dwindle = {
              pseudotile = false;

              use_active_for_splits = true;
              force_split = 0; # Follows Mouse
              smart_split = false;
              preserve_split = true;

              smart_resizing = true;
            };

            xwayland = {
              enabled = true;
              force_zero_scaling = true;
              use_nearest_neighbor = true;
            };

            # windowrule = [
            # ];

            input = {
              kb_layout = "us";

              numlock_by_default = false;

              follow_mouse = 1;
              focus_on_close = 1;

              left_handed = false;
              natural_scroll = false;

              touchpad = {
                natural_scroll = true;

                tap-to-click = true;
                tap-and-drag = true;
                drag_lock = true;

                disable_while_typing = true;
              };

              touchdevice = {
                enabled = true;
              };

              tablet = {
                left_handed = false;
              };
            };

            cursor = {
              no_hardware_cursors = false;

              enable_hyprcursor = true;
              sync_gsettings_theme = true;

              persistent_warps = true;

              no_warps = false;

              hide_on_key_press = false;
              hide_on_touch = true;
            };

            binds = {
              disable_keybind_grabbing = true;
              pass_mouse_when_bound = false;

              window_direction_monitor_fallback = true;
            };

            gestures = {
              # Touchpad
              workspace_swipe_invert = true;

              # Touchscreen
              workspace_swipe_touch = false;
              workspace_swipe_touch_invert = false;

              workspace_swipe_create_new = true;
              workspace_swipe_forever = true;
            };

            decoration = {
              dim_special = 0.25;

              rounding = builtins.floor (design_factor / 2); # 8

              active_opacity = 1.0;
              fullscreen_opacity = 1.0;
              inactive_opacity = 1.0;

              dim_inactive = false;
              dim_strength = 0.0;

              blur.enabled = false;
              shadow.enabled = false;
            };

            animations = {
              enabled = true;

              bezier = [
                "linear, 0, 0, 1, 1" # https://www.cssportal.com/css-cubic-bezier-generator/#0,0,1,1
              ];

              animation = [
                "global, 1, 1.0, linear"
                "border, 1, 1.0, linear"
                "windows, 1, 1.0, linear"
                "windowsIn, 1, 1.0, linear"
                "windowsOut, 1, 1.0, linear"
                "fadeIn, 1, 1.0, linear"
                "fadeOut, 1, 1.0, linear"
                "fade, 1, 1.0, linear"
                "layers, 1, 1.0, linear"
                "layersIn, 1, 1.0, linear"
                "layersOut, 1, 1.0, linear"
                "fadeLayersIn, 1, 1.0, linear"
                "fadeLayersOut, 1, 1.0, linear"
                "workspaces, 1, 1.0, linear"
                "workspacesIn, 1, 1.0, linear"
                "workspacesOut, 1, 1.0, linear"
              ];
              # Name, On/Off, Speed, Bezier
            };

            plugin = {
              # dynamic-cursors = {
              #   enabled = true;

              #   hyprcursor = {
              #     enabled = true;
              #   };

              #   mode = "rotate";
              #   threshold = 1;
              #   rotate = {
              #     length = cursor.size;
              #   };

              #   shake = {
              #     enabled = true;
              #     ipc = true;

              #     effects = true;
              #   };
              # }; # FIXME: Build Failure
            };
          };
        };

        xdg = {
          mime.enable = true;

          mimeApps = {
            enable = true;

            associations = {
              added = config.xdg.mime.addedAssociations;

              removed = config.xdg.mime.removedAssociations;
            };

            defaultApplications = config.xdg.mime.defaultApplications;
          };

          configFile = {
            "mimeapps.list".force = true;
          };
        };

        gtk = {
          enable = true;

          theme = {
            name = "Adwaita-dark";
            package = pkgs.adw-gtk3;
          };

          iconTheme = {
            name = "Papirus-Dark";
            package = (
              pkgs.papirus-icon-theme.override {
                color = "black";
              }
            );
          };

          cursorTheme = {
            name = cursor.theme.name;
            package = cursor.theme.package;
            size = cursor.size;
          };

          font = {
            name = font_preferences.name.sans_serif;
            package = font_preferences.package;
            size = font_preferences.size;
          };
        };

        qt = {
          enable = true;
          platformTheme.name = "qtct";
        };

        services = {
          poweralertd.enable = true;

          udiskie = {
            enable = true;
            package = pkgs.udiskie;

            automount = true;
            tray = "always";
            notify = true;

            # settings = { };
          };
        };

        programs = {
          dircolors = {
            enable = true;
            package = (
              pkgs.coreutils-full.override {
                aclSupport = true;
                withOpenssl = true;
              }
            );

            enableBashIntegration = true;
          };

          kubecolor = {
            enable = true;
            package = pkgs.kubecolor;

            enableAlias = true;

            settings = {
              kubectl = pkgs.lib.getExe pkgs.kubectl;
              preset = "dark";
            };
          };

          # gradle = {
          #   enable = true;
          #   package = pkgs.gradle;
          # }; # flutter adds the compatible versions

          matplotlib = {
            enable = true;

            config = {
              axes = {
                grid = true;
              };
            };
          };

          keepassxc = {
            enable = true;
            package = (
              pkgs.keepassxc.override {
                withKeePassBrowser = true;
                withKeePassBrowserPasskeys = true;
                withKeePassFDOSecrets = true;
                withKeePassKeeShare = true;
                withKeePassNetworking = true;
                withKeePassSSHAgent = true;
                withKeePassYubiKey = true;
              }
            );

            # settings = { };
          };

          gh = {
            enable = true;
            package = pkgs.gh;
            extensions = with pkgs; [
              gh-contribs
              gh-notify
              gh-skyline
            ];

            gitCredentialHelper = {
              enable = true;

              hosts = [
                "https://github.com"
                "https://gist.github.com"
              ];
            };

            settings = {
              git_protocol = "https";

              editor = "nano";

              # aliases = { };
            };
          };

          awscli = {
            enable = true;
            package = pkgs.awscli2;

            settings = {
              default = {
                output = "json";
              };
            };

            # credentials = { };
          };

          wofi = {
            enable = true;
            package = pkgs.wofi;

            settings = {
              normal_window = false;
              layer = "overlay";
              location = "center";

              gtk_dark = true;
              columns = 2;
              dynamic_lines = false;
              height = "50%";
              hide_scroll = false;

              hide_search = false;
              prompt = "Search";
              show_all = true;
              allow_markup = true;
              allow_images = true;
              image_size = 32;
              no_actions = true;

              insensitive = true;

              single_click = true;
              term = "foot";
            };

            style = ''
              window {
                border-radius: ${toString design_factor}px;
              }

              #outer-box {
                padding: 16px;
              }

              #inner-box {
                margin-top: 16px;
              }

              #entry {
                margin-top: 4px;
                margin-bottom: 4px;
              }

              #img {
                margin-right: 4px;
              }
            '';
          };

          vscode = {
            enable = true;
            package = pkgs.vscodium;
            mutableExtensionsDir = false;

            profiles = {
              default = {
                extensions =
                  with pkgs.vscode-extensions;
                  [
                    aaron-bond.better-comments
                    adpyke.codesnap
                    albymor.increment-selection
                    alefragnani.bookmarks
                    alexisvt.flutter-snippets
                    anweber.vscode-httpyac
                    bierner.color-info
                    bierner.docs-view
                    bierner.emojisense
                    bierner.github-markdown-preview
                    bierner.markdown-checkbox
                    bierner.markdown-emoji
                    bierner.markdown-footnotes
                    bierner.markdown-mermaid
                    bierner.markdown-preview-github-styles
                    bradgashler.htmltagwrap
                    budparr.language-hugo-vscode
                    chanhx.crabviz
                    codezombiech.gitignore
                    coolbear.systemd-unit-file
                    cweijan.vscode-database-client2
                    dart-code.dart-code
                    dart-code.flutter
                    davidanson.vscode-markdownlint
                    dbaeumer.vscode-eslint
                    dendron.adjust-heading-level
                    docker.docker
                    dotenv.dotenv-vscode
                    ecmel.vscode-html-css
                    esbenp.prettier-vscode
                    fabiospampinato.vscode-open-in-github
                    firefox-devtools.vscode-firefox-debug
                    formulahendry.auto-close-tag
                    formulahendry.auto-rename-tag
                    foxundermoon.shell-format
                    github.vscode-github-actions
                    github.vscode-pull-request-github
                    grapecity.gc-excelviewer
                    gruntfuggly.todo-tree
                    hars.cppsnippets
                    hbenl.vscode-test-explorer
                    ibm.output-colorizer
                    iciclesoft.workspacesort
                    iliazeus.vscode-ansi
                    james-yu.latex-workshop
                    jbockle.jbockle-format-files
                    jellyedwards.gitsweep
                    jnoortheen.nix-ide
                    jock.svg
                    lokalise.i18n-ally
                    mads-hartmann.bash-ide-vscode
                    mathiasfrohlich.kotlin
                    mechatroner.rainbow-csv
                    mishkinf.goto-next-previous-member
                    mkhl.direnv
                    moshfeu.compare-folders
                    ms-kubernetes-tools.vscode-kubernetes-tools
                    ms-python.black-formatter
                    ms-python.debugpy
                    ms-python.isort
                    ms-python.python
                    ms-vscode.cmake-tools
                    ms-vscode.cpptools # Unfree
                    ms-vscode.hexeditor
                    ms-vscode.live-server
                    ms-vscode.makefile-tools
                    ms-vscode.test-adapter-converter
                    njpwerner.autodocstring
                    oderwat.indent-rainbow
                    platformio.platformio-vscode-ide
                    quicktype.quicktype
                    redhat.vscode-xml
                    redhat.vscode-yaml
                    rioj7.commandonallfiles
                    rubymaniac.vscode-paste-and-indent
                    ryu1kn.partial-diff
                    shardulm94.trailing-spaces
                    spywhere.guides
                    stylelint.vscode-stylelint
                    tailscale.vscode-tailscale
                    tamasfe.even-better-toml
                    timonwong.shellcheck
                    usernamehw.errorlens
                    vincaslt.highlight-matching-tag
                    vscjava.vscode-gradle
                    vscode-icons-team.vscode-icons
                    wmaurer.change-case
                    xdebug.php-debug
                    zainchen.json
                  ]
                  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                    {
                      name = "unique-lines";
                      publisher = "bibhasdn";
                      version = "1.0.0";
                      sha256 = "W0ZpZ6+vjkfNfOtekx5NWOFTyxfWAiB0XYcIwHabFPQ=";
                    }
                    {
                      name = "vscode-sort";
                      publisher = "henriiik";
                      version = "0.2.5";
                      sha256 = "pvlSlWJTnLB9IbcVsz5HypT6NM9Ujb7UYs2kohwWVWk=";
                    }
                    {
                      name = "vscode-sort-json";
                      publisher = "richie5um2";
                      version = "1.20.0";
                      sha256 = "Jobx5Pf4SYQVR2I4207RSSP9I85qtVY6/2Nvs/Vvi/0=";
                    }
                    {
                      name = "pubspec-assist";
                      publisher = "jeroen-meijer";
                      version = "2.3.2";
                      sha256 = "+Mkcbeq7b+vkuf2/LYT10mj46sULixLNKGpCEk1Eu/0=";
                    }
                    {
                      name = "arb-editor";
                      publisher = "Google";
                      version = "0.2.2";
                      sha256 = "sSYiudnBRFTsio0uNJ6+FOzkjO92wGDvGJYJcRrzWX0=";
                    }
                    {
                      name = "vscode-serial-monitor";
                      publisher = "ms-vscode";
                      version = "0.13.251128001";
                      sha256 = "eTQcLyF6DMvzDByKLw2KR8PrjVwejsOU60Hew7IOmY8=";
                    }
                    {
                      name = "dms-theme";
                      publisher = "danklinux";
                      version = "0.0.3";
                      sha256 = "sha256-MI1x1wiqvwg/N89oMuNVp0qlRT84ubvuMjtpkX0WKQY=";
                    }
                  ];

                enableUpdateCheck = true;
                enableExtensionUpdateCheck = true;

                # userSettings = { };
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
        };
      }
    ];

    users.root = { };
    users.bitscoper = { };

    verbose = true;
  };
}

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: Cockpit > Login
# FIXME: ELAN7001 SPI Fingerprint Sensor
# FIXME: MariaDB > Login
# FIXME: Wofi > Window > Border Radius > Transperant Background
