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
        url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-25.11.tar.gz";
      })
      {
        config = config.nixpkgs.config;
      };

  homeManagerFlake = builtins.getFlake "github:nix-community/home-manager/master";
  hyprlandFlake = builtins.getFlake "github:hyprwm/Hyprland/main?submodules=1";
  freesmLauncherFlake = builtins.getFlake "github:FreesmTeam/FreesmLauncher/develop";
  catppuccinThemeFlake = builtins.getFlake "github:catppuccin/nix";

  # p="$(nix eval --raw nixpkgs#path)/pkgs/development/mobile/androidenv/querypackages.sh"; for t in packages images addons extras licenses; do sh "$p" "$t"; done
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    numLatestPlatformVersions = 1;
    platformVersions = [
      "latest"
      "28"
      "29"
      "30"
      "31"
      "32"
      "33"
      "34"
      "35"
      "36"
      "36.1"
      "37.0"
    ];
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;

    platformToolsVersion = "latest";
    buildToolsVersions = [
      "latest"
      "35.0.0"
      "36.1.0"
      "37.0.0"
    ];

    includeNDK = true;
    ndkVersions = [
      "latest"
      "28.2.13676358"
      "29.0.14206865"
    ];

    cmdLineToolsVersion = "latest";
    toolsVersion = "latest";

    includeCmake = true;
    cmakeVersions = [
      "latest"
      "3.22.1"
      "4.1.2"
    ];

    includeExtras = [
      "extras;google;auto"
      "extras;google;simulators"
    ];

    includeEmulator = true;
    emulatorVersion = "latest";

    includeSystemImages = true;
    systemImageTypes = [
      "default" # Vanilla
    ];
    abiVersions = [
      "arm64-v8a"
      "armeabi-v7a"
      "x86_64"
    ];

    includeSources = false;
  };

  design_factor = 16;

  fontPreferences = {
    package = pkgs.nerd-fonts.noto;

    name = {
      mono = "NotoMono Nerd Font Mono";
      sans_serif = "NotoSans Nerd Font";
      serif = "NotoSerif Nerd Font";
      emoji = "Noto Color Emoji";
    };

    size = builtins.floor (design_factor * 0.75); # 12
  };

  wallpaper = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/zhichaoh/catppuccin-wallpapers/refs/heads/main/os/nix-black-4k.png";
  };

  tlsCertificateFiles =
    pkgs.runCommand "tlsCertificate"
      {
        CN = config.networking.fqdn;
      }
      ''
        mkdir -p $out
        ${pkgs.openssl}/bin/openssl ecparam -name secp521r1 -genkey -noout -out $out/private.key
        ${pkgs.openssl}/bin/openssl req -new -x509 -key $out/private.key -out $out/certificate.crt -days 36500 -subj "/CN=$CN"
        cat $out/private.key $out/certificate.crt > $out/concatenated.pem
        cp $out/certificate.crt $out/ca.crt
      '';
  tlsCertificatePrivateKeyFile = "${tlsCertificateFiles}/private.key";
  tlsCertificateFile = "${tlsCertificateFiles}/certificate.crt";
  tlsCertificateConcatenatedFile = "${tlsCertificateFiles}/concatenated.pem";
  tlsCACertificateFile = "${tlsCertificateFiles}/ca.crt";
in
{
  _class = "nixos";

  imports = [
    homeManagerFlake.nixosModules.home-manager
    catppuccinThemeFlake.nixosModules.catppuccin
    ./hardware-configuration.nix
    ./secrets.nix
  ];

  boot = {
    isContainer = false;

    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;

        efiSupport = true;
        zfsSupport = true;
        enableCryptodisk = true;
        useOSProber = true;

        fsIdentifier = "uuid";
        device = "nodev";

        gfxmodeEfi = "1920x1080,auto";
        gfxpayloadEfi = "keep";
        splashMode = "stretch";

        configurationLimit = 100;
        extraEntriesBeforeNixOS = false;

        memtest86 = {
          enable = true;

          params = [
            "btrace"
          ];
        };

        forceInstall = false;
      };

      timeout = 2; # 2 Seconds
    };

    kernel = {
      enable = true;

      sysctl = {
        "net.ipv4.tcp_syncookies" = true;
      };
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

    extraModulePackages = with config.boot.kernelPackages; [
      # apfs # FIXME: Build Failure
      # zfs # FIXME: Build Failure
      cpupower
      mm-tools
      openafs
      tmon
      turbostat
      usbip
    ];

    hardwareScan = true;

    kernelModules = [
      "at24"
      "ee1004"
      "i915"
      "kvm-intel"
      "spd5118"
    ];

    blacklistedKernelModules = [
      "efifb"
      "simplefb"
    ];

    extraModprobeConfig = ''
      options kvm_intel nested=1
      options kvm report_ignored_msrs=0
    '';

    kernelParams = [
      "boot.shell_on_fail"
      "initcall_blacklist=simpledrm_platform_driver_init"
      "intel_iommu=on"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "mitigations=auto"
      "splash"
      "rd.systemd.show_status=true"
      "rd.udev.log_level=err"
      "udev.log_level=err"
      "udev.log_priority=err"
    ];

    initrd = {
      enable = true;

      kernelModules = config.boot.kernelModules;
      availableKernelModules = [
        "ahci"
        "nvme"
        "rtsx_usb_sdmmc"
        "sd_mod"
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ];

      systemd = {
        enable = true;
        package = config.systemd.package;
      };

      network.enable = true;

      verbose = true;
    };

    growPartition = true;

    tmp = {
      cleanOnBoot = true;

      zramSettings = {
        fs-type = "ext4";
        compression-algorithm = "zstd";
      };
    };

    kexec.enable = true;

    crashDump = {
      enable = true;

      kernelParams = [
        "1" # 1 = runlevel 1 / Single-User Mode
        "boot.shell_on_fail"
      ];

      reservedMemory = "128M";
    };

    consoleLogLevel = 4; # 4 = KERN_WARNING

    plymouth = {
      enable = true;

      themePackages = with pkgs; [
        (catppuccin-plymouth.override {
          variant = config.catppuccin.flavor;
        })
      ];
      theme = "catppuccin-${config.catppuccin.flavor}";

      font = "${pkgs.nerd-fonts.noto}/share/fonts/truetype/NerdFonts/Noto/NotoSansNerdFont-Regular.ttf";

      extraConfig = ''
        UseFirmwareBackground=true
      '';
    };
  };

  zramSwap = {
    enable = true;
    algorithm = config.boot.tmp.zramSettings.compression-algorithm;
  };

  time = {
    timeZone = "Asia/Dhaka";
    hardwareClockInLocalTime = false;
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

    activationScripts = {
      copyOnlyOfficeFonts =
        let
          fonts = config.fonts.packages;
        in
        ''
          FONTDIR="/var/lib/onlyoffice-fonts/"
          mkdir -p "$FONTDIR"

          ${lib.concatMapStrings (package: ''
            if [ -d "${package}/share/fonts" ]; then
              find "${package}/share/fonts" -type f \( \
                -name "*.bdf" -o \
                -name "*.otf" -o \
                -name "*.pcf" -o \
                -name "*.pfa" -o \
                -name "*.pfb" -o \
                -name "*.ttc" -o \
                -name "*.ttf" \
              \) -exec cp -f {} "$FONTDIR" \;
            fi
          '') fonts}

          chmod -R 777 "$FONTDIR"
        '';
    };

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

      sandbox = true;
      auto-optimise-store = true;

      require-sigs = true;
      trusted-substituters = config.nix.settings.substituters;
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      trusted-users = [
        "root"
        "@wheel"
      ];

      substituters = [
        "https://hyprland.cachix.org"
      ];

      cores = 0; # 0 = All
      max-jobs = 1;
    };

    gc = {
      automatic = false; # Enabled nh clean Instead
      dates = "weekly";
      persistent = true;
    };
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      android_sdk.accept_license = true;

      permittedInsecurePackages = [
        "opendkim-2.11.0-Beta2"
        "ventoy-gtk3-1.1.12"
      ];
    };

    overlays = [
      (final: prev: {
        libvirt = stableNixPackages.libvirt;
      })
      (final: prev: {
        hyprland = (
          hyprlandFlake.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.override {
            debug = false;
            enableXWayland = true;
            withSystemd = true;
            wrapRuntimeDeps = true;
          }
        );
      })
      (final: prev: {
        xdg-desktop-portal-hyprland =
          hyprlandFlake.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland.override
            {
              debug = false;
            };
      })
      freesmLauncherFlake.overlays.default
    ];
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
        addons = with pkgs; [
          fcitx5-openbangla-keyboard
        ];
        waylandFrontend = true;

        ignoreUserConfig = false;
      };

      enableGtk3 = true;
      enableGtk2 = true;
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
      enableHardening = true;
    };

    useDHCP = false; # Managed by NetworkManager
    dhcpcd.enable = false;

    networkmanager = {
      enable = true;
      package = (
        pkgs.networkmanager.override {
          withSystemd = true;
        }
      );
      plugins = with pkgs; [
        networkmanager-l2tp
        networkmanager-openvpn
        networkmanager-ssh
        networkmanager-sstp
      ];

      ethernet.macAddress = "permanent";

      wifi = {
        backend = "wpa_supplicant";

        powersave = false;

        scanRandMacAddress = true;
        macAddress = "permanent";
      };

      dhcp = "internal";
      dns = "systemd-resolved";

      logLevel = "WARN";
    };

    firewall = {
      enable = true;

      allowPing = true;

      allowedTCPPorts = [
        config.home-manager.users.root.services.wayvnc.settings.port
      ];
      allowedUDPPorts = config.networking.firewall.allowedTCPPorts;

      trustedInterfaces = [
        "virbr0"
      ];
    };

    nameservers = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
      "2620:fe::fe#dns.quad9.net"
      "2620:fe::9#dns.quad9.net"
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
    forcePageTableIsolation = true;

    tpm2.enable = true;

    lockKernelModules = false;

    rtkit.enable = true;

    sudo = {
      enable = true;
      package = (
        pkgs.sudo.override {
          withInsults = false; # Includes Profanity
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

      adminIdentities = [
        "unix-group:wheel"
      ];

      debug = false;
    };

    soteria = {
      enable = true;
      package = pkgs.soteria;
    };

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
          fprintAuth = true;

          logFailures = true;
          nodelay = false;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };

          showMotd = true;
        };

        cockpit = {
          unixAuth = true;
          fprintAuth = true;

          logFailures = true;
          nodelay = false;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };

          showMotd = true;
        };

        sshd = {
          unixAuth = true;
          fprintAuth = true;

          logFailures = true;
          nodelay = false;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };

          showMotd = true;
        };

        hyprlock = {
          unixAuth = true;
          fprintAuth = true;

          logFailures = true;
          nodelay = false;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };

          showMotd = true;
        };

        sudo = {
          unixAuth = true;
          fprintAuth = true;

          logFailures = true;
          nodelay = false;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };

          showMotd = true;
        };

        polkit-1 = {
          unixAuth = true;
          fprintAuth = true;

          logFailures = true;
          nodelay = false;

          enableGnomeKeyring = true;

          gnupg = {
            enable = true;
            storeOnly = false;
            noAutostart = false;
          };

          showMotd = true;
        };
      };
    };

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
      libreelec-dvb-firmware
      linux-firmware
      sof-firmware
    ];

    firmwareCompression = "zstd";

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
        # intel-ocl # FIXME: Build Failure
        intel-compute-runtime
        intel-gmmlib
        intel-media-driver
        libvpl
        vpl-gpu-rt
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
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

      hsphfpd.enable = false; # Conflicts with WirePlumber

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
      # extraBackends = with pkgs; [

      # ];
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
      package = (
        pkgs.libvirt.override {
          enableCeph = true;
          enableGlusterfs = true;
          enableIscsi = true;
          enableXen = false;
          enableZfs = true;
        }
      );

      qemu = {
        # package = (
        #   pkgs.qemu_full.override {
        #     alsaSupport = false;
        #     canokeySupport = false; # Marked as Broken
        #     capstoneSupport = true;
        #     cephSupport = true;
        #     enableBlobs = true;
        #     enableDocs = true;
        #     enableTools = true;
        #     glusterfsSupport = true;
        #     gtkSupport = true;
        #     guestAgentSupport = true;
        #     jackSupport = false;
        #     libiscsiSupport = true;
        #     ncursesSupport = true;
        #     numaSupport = true;
        #     openGLSupport = true;
        #     pipewireSupport = true;
        #     pluginsSupport = true;
        #     pulseSupport = false;
        #     rutabagaSupport = true;
        #     sdlSupport = true;
        #     seccompSupport = true;
        #     smartcardSupport = true;
        #     smbdSupport = true;
        #     spiceSupport = true;
        #     tpmSupport = true;
        #     uringSupport = true;
        #     usbredirSupport = true;
        #     valgrindSupport = true;
        #     virglSupport = true;
        #     vncSupport = true;
        #     xenSupport = false;
        #   }
        # ); # FIXME: Missing Binaries
        package = pkgs.qemu;

        vhostUserPackages = with pkgs; [
          virtiofsd
        ];

        swtpm = {
          enable = true;
          package = pkgs.swtpm;
        };

        runAsRoot = true;
      };
    };

    spiceUSBRedirection.enable = true;

    podman = {
      enable = true;
      package = pkgs.podman;
      # extraPackages = with pkgs; [

      # ];
      extraRuntimes = with pkgs; [
        runc
      ];

      dockerCompat = true;
      dockerSocket.enable = true;

      networkSocket = {
        enable = true;

        server = "ghostunnel";

        listenAddress = "0.0.0.0";
        port = 2376;

        tls = {
          cert = tlsCertificateFile;
          key = tlsCertificatePrivateKeyFile;

          cacert = tlsCACertificateFile;
        };

        openFirewall = true;
      };

      defaultNetwork.settings = {
        dns_enabled = true;
      };
    };

    oci-containers.backend = "podman";

    waydroid = {
      enable = true;
      package = (
        pkgs.waydroid-nftables.override {
          withNftables = true;
        }
      );
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

    tmpfiles.rules = [
      "L+ /lib/modules/ - - - - /run/current-system/kernel-modules/lib/modules/"
      "d /var/lib/swtpm-localca 0750 tss root -"
    ];
  };

  services = {
    timesyncd = {
      enable = false; # FIXME: Disabled due to Misbehavior

      servers = config.networking.timeServers;
      fallbackServers = config.networking.timeServers;
    };

    cloudflare-warp = {
      enable = true;
      package = (
        pkgs.cloudflare-warp.override {
          headless = false;
        }
      );

      openFirewall = true;
    };

    resolved = {
      enable = true;

      settings = {
        Resolve = {
          DNSSEC = true;
          DNSOverTLS = true;

          DNS = config.networking.nameservers;
          FallbackDNS = [ ];

          Domains = [
            "~."
          ];
        };
      };
    };

    fwupd = {
      enable = true;
      package = (
        pkgs.fwupd.override {
          enableFlashrom = true;
        }
      );
    };

    upower = {
      enable = true;
      package = (
        pkgs.upower.override {
          withDocs = true;
          withIntrospection = true;
          withSystemd = true;
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

    power-profiles-daemon = {
      enable = true;
      package = pkgs.power-profiles-daemon;
    };

    thermald = {
      enable = true;
      package = pkgs.thermald;

      ignoreCpuidCheck = false;

      debug = false;
    };

    colord.enable = true;

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
      package = pkgs.udisks;

      mountOnMedia = false;
    };

    smartd = {
      enable = false; # FIXME: Fails to Start

      autodetect = true;

      notifications = {
        mail.enable = false;
        systembus-notify.enable = false;
        test = false;
        wall.enable = true;
      };
    };

    zram-generator = {
      enable = true;
      package = pkgs.zram-generator;
    };

    dbus = {
      enable = true;
      dbusPackage = (
        pkgs.dbus.override {
          enableSystemd = true;
        }
      );

      implementation = "broker";

      packages = with pkgs; [
        libvirt-dbus
      ];
    };

    accounts-daemon.enable = true;

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

      ly = {
        enable = true;
        package = pkgs.ly;

        x11Support = false;
      };

      defaultSession = "hyprland-uwsm";

      autoLogin.enable = false;

      logToJournal = true;
    };

    gnome = {
      gnome-keyring.enable = true;

      gcr-ssh-agent = {
        enable = true;
        package = (
          pkgs.gcr_4.override {
            systemdSupport = true;
          }
        );
      };
    };

    pipewire = {
      enable = true;
      package = (
        pkgs.pipewire.override {
          bluezSupport = true;
          enableSystemd = true;
          raopSupport = true;
          rocSupport = true;
          vulkanSupport = true;
          zeroconfSupport = true;
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

    saned.enable = true;

    gpsd = {
      enable = true;

      readonly = true;

      listenany = true;
      port = 2947;

      debugLevel = 0; # 0 = No Debugging
    };

    phpfpm = {
      phpPackage =
        (pkgs.php85.override {
          argon2Support = true;
          cgiSupport = true;
          cgotoSupport = true;
          cliSupport = true;
          fpmSupport = true;
          ipv6Support = true;
          pearSupport = true;
          pharSupport = true;
          phpdbgSupport = true;
          staticSupport = true;
          systemdSupport = true;
          valgrindSupport = true;
          zendMaxExecutionTimersSupport = false;
          zendSignalsSupport = true;
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
                mysqli
                mysqlnd
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

    kubernetes = {
      package = pkgs.kubernetes;
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
          isNixos = true;
          linkOpenssl = true;
          withPAM = true;
        }
      );

      allowSFTP = true;

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

      authorizedKeysInHomedir = true;

      settings =
        let
          banner = pkgs.writeText "opesshBanner.txt" "${config.networking.fqdn}";
        in
        {
          Banner = toString banner;
          LogLevel = "ERROR";
          PasswordAuthentication = true;
          PermitRootLogin = "yes";
          StrictModes = true;
          UseDns = true;
          X11Forwarding = false;
        };

      openFirewall = true;
    };

    cockpit = {
      enable = true;
      package = (
        pkgs.cockpit.override {
          withBranding = true;
        }
      );
      plugins = with pkgs; [
        cockpit-files
        cockpit-machines
        cockpit-podman
      ];

      port = 9090;
      allowed-origins = [
        "*"
      ];

      showBanner = true;

      settings = {
        WebService = {
          AllowUnencrypted = false;

          LoginTo = true;
          AllowMultiHost = true;
        };
      };

      openFirewall = true;
    };

    postgresql = {
      enable = true;
      package = (
        pkgs.postgresql_18.override {
          bonjourSupport = false; # FIXME: Build Failure
          curlSupport = true;
          gssSupport = true;
          jitSupport = true;
          nlsSupport = false; # FIXME: Build Failure
          numaSupport = true;
          pamSupport = true;
          pythonSupport = true;
          selinuxSupport = true;
          systemdSupport = true;
          uringSupport = true;
        }
      );

      enableTCPIP = true;
      enableJIT = false; # FIXME: Build Failure

      settings = pkgs.lib.mkForce {
        jit = true;

        listen_addresses = "*";
        port = 5432;

        logging_collector = true;
        log_destination = "syslog";
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

      initialScript = pkgs.writeText "postgresqlInitialScript.sql" ''
        ALTER USER postgres WITH PASSWORD '${config.secrets.password_1}';
      '';
    };

    mysql = {
      enable = true;
      package = (
        pkgs.mariadb_118.override {
          withEmbedded = true;
          withNuma = true;
          withStorageMroonga = true;
          withStorageRocks = true;
        }
      );

      settings = {
        mysqld = {
          bind-address = "*";
          port = 3306;

          sql_mode = "";
        };
      };

      initialScript = pkgs.writeText "mariadbInitialScript.sql" ''
        FLUSH PRIVILEGES;
        CREATE USER IF NOT EXISTS 'root'@'localhost';
        CREATE USER IF NOT EXISTS 'root'@'%';
        ALTER USER 'root'@'localhost' IDENTIFIED BY '${config.secrets.password_1}';
        ALTER USER 'root'@'%' IDENTIFIED BY '${config.secrets.password_1}';
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
        GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
        FLUSH PRIVILEGES;
      '';
    };

    gvfs = {
      enable = true;
      package = (
        pkgs.gvfs.override {
          gnomeSupport = false;
          googleSupport = false;
          udevSupport = true;
        }
      );
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

          smtpd_tls_security_level = "encrypt";
          smtp_tls_security_level = "encrypt";

          smtpd_tls_chain_files = [
            tlsCertificateConcatenatedFile
          ];
          smtp_tls_CAfile = tlsCACertificateFile;
        };
      };
    };

    opendkim = {
      enable = true;

      domains = "csl:${config.networking.fqdn}";
      selector = "default";
    }; # Marked as Insecure

    dovecot2 = {
      enable = true;
      package = (
        pkgs.dovecot.override {
          withLDAP = true;
          withMySQL = true;
          withPCRE2 = true;
          withPgSQL = true;
          withSQLite = true;
          withUnwind = true;
        }
      );

      enablePAM = true;
      showPAMFailure = true;
      createMailUser = true;

      settings = {
        dovecot_config_version = config.services.dovecot2.package.version;
        dovecot_storage_version = config.services.dovecot2.package.version;

        protocols = {
          imap = true;
          lmtp = true;
          pop3 = true;
        };

        ssl_server_cert_file = tlsCertificateFile;
        ssl_server_key_file = tlsCertificatePrivateKeyFile;
        ssl_server_ca_file = tlsCACertificateFile;
      };
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
        password = config.secrets.password_1;
      };

      extraConfig = ''
        <location>${config.networking.fqdn}</location>
        <admin>bitscoper@${config.networking.fqdn}</admin>
        <authentication>
          <source-password>${config.secrets.password_2}</source-password>
          <relay-password>${config.secrets.password_2}</relay-password>
        </authentication>
        <directory>
          <yp-url-timeout>15</yp-url-timeout>
          <yp-url>http://dir.xiph.org/cgi-bin/yp-cgi</yp-url>
        </directory>
        <paths>
        <ssl-certificate>${tlsCertificateConcatenatedFile}</ssl-certificate>
        </paths>
        <logging>
          <loglevel>2</loglevel>
        </logging>
        <server-id>${config.networking.fqdn}</server-id>
      ''; # <loglevel>2</loglevel> = Warn
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

    cloudflared = {
      enable = true;
      package = pkgs.cloudflared;
    };

    logrotate = {
      enable = true;

      allowNetworking = true;
      checkConfig = true;
    };

    flatpak = {
      enable = true;
      package = (
        pkgs.flatpak.override {
          withDconf = true;
          withMan = true;
          withPolkit = true;
          withSystemd = true;
        }
      );
    };
  };

  programs = {
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

    nautilus-open-any-terminal = {
      enable = true;
      terminal = "foot";
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

    java = {
      enable = true;
      package = (
        pkgs.jdk.override {
          enableGtk = true;
        }
      );

      binfmt = true;
    };

    direnv = {
      enable = true;
      package = pkgs.direnv;

      nix-direnv.enable = true;
      loadInNixShell = true;

      enableBashIntegration = true;

      silent = false;
    };

    zoxide = {
      enable = true;
      package = (
        pkgs.zoxide.override {
          withFzf = false;
        }
      );

      enableBashIntegration = true;

      flags = [
        "--cmd cd"
      ];
    };

    yazi = {
      enable = true;
      package = pkgs.yazi;

      plugins = with pkgs.yaziPlugins; {
        inherit
          chmod
          clipboard
          compress
          convert
          diff
          drag
          gvfs
          lazygit
          mount
          rsync
          smart-filter
          smart-paste
          sudo
          time-travel
          vcs-files
          wl-clipboard
          ;
      };

      settings = {
        yazi = {
          mgr = {
            sort_by = "natural";
            sort_sensitive = true;
            sort_reverse = false;
            sort_dir_first = true;
            sort_translit = false;
            linemode = "mtime";
            show_hidden = true;
            show_symlink = true;
          };

          preview = {
            wrap = "yes";
            image_quality = 90; # Highest is 90
          };

          input = {
            cursor_blink = true;
          };

          confirm = {
            cursor_blink = true;
          };

          pick = {
            cursor_blink = true;
          };

          which = {
            sort_by = "key";
            sort_sensitive = true;
            sort_reverse = false;
            sort_translit = false;
          };
        }; # yazi.toml
      };
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
          pkgs.pinentry-tty.override {
            withLibsecret = true;
          }
        );
      };

      dirmngr.enable = true;
    };

    ssh = {
      package = config.services.openssh.package;

      startAgent = false; # `services.gnome.gcr-ssh-agent.enable' and `programs.ssh.startAgent' cannot both be enabled at the same time.
      agentTimeout = null;
    };

    git = {
      enable = true;
      package = (
        pkgs.gitFull.override {
          guiSupport = true;
          sendEmailSupport = true;
          svnSupport = true;
          withLibsecret = true;
          withManual = true;
          withpcre2 = true;
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

        credential.helper = "${config.programs.git.package}/bin/git-credential-libsecret";

        user = {
          name = "Abdullah As-Sadeed";
          email = "bitscoper@tutanota.com";
        };
      };
    };

    nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
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

    usbtop.enable = true;

    nano.enable = false;

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

    xwayland.enable = true;

    hyprland = {
      enable = true;
      package = pkgs.hyprland;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      withUWSM = true;
      xwayland.enable = true;
    };

    gamemode = {
      enable = true;
      enableRenice = true;
    };

    dconf = {
      enable = true;
      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
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
          };
        }
      ];
    };

    foot = {
      enable = true;
      package = pkgs.foot;

      enableBashIntegration = true;

      settings = {
        main = {
          term = "foot";
          login-shell = "no";

          dpi-aware = "yes";
          initial-window-mode = "windowed";
          initial-color-theme = "dark";
          pad = "${toString (design_factor * 2)}x0x0x0 center-when-maximized-and-fullscreen"; # 32

          font = "${fontPreferences.name.mono}:pixelsize=${toString design_factor}";
          box-drawings-uses-font-glyphs = "yes";
          horizontal-letter-offset = 0;
          vertical-letter-offset = 0;

          selection-target = "primary";
        };

        tweak = {
          sixel = "yes";
          surface-bit-depth = "16-bit";
          font-monospace-warn = "yes";
        };

        security.osc52 = "enabled";

        url = {
          osc8-underline = "always";
        };

        bell = {
          system = "yes";
        };

        scrollback = {
          indicator-position = "relative";
          indicator-format = "line";
        };

        cursor = {
          style = "beam";
          unfocused-style = "hollow";
          blink = "yes";
        };

        mouse = {
          hide-when-typing = "no";
        };
      };
    };

    seahorse.enable = true;

    system-config-printer.enable = true;

    virt-manager = {
      enable = true;
      package = (
        pkgs.virt-manager.override {
          spiceSupport = true;
        }
      );
    };

    wayvnc = {
      enable = true;
      package = pkgs.wayvnc;
    };

    obs-studio = {
      enable = true;
      package = (
        pkgs.obs-studio.override {
          alsaSupport = false;
          browserSupport = true;
          pipewireSupport = true;
          pulseaudioSupport = false;
          scriptingSupport = true;
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

    ghidra = {
      enable = true;
      package = pkgs.ghidra;
      gdb = true;
    };

    localsend = {
      enable = true;
      package = pkgs.jocalsend;

      openFirewall = true;
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
          fontPreferences.name.mono
        ];

        sansSerif = [
          fontPreferences.name.sans_serif
        ];

        serif = [
          fontPreferences.name.serif
        ];

        emoji = [
          fontPreferences.name.emoji
        ];
      };

      includeUserConf = true;
    };
  };

  environment = {
    shells = [
      config.users.defaultUserShell
    ];

    enableAllTerminfo = true;

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    systemPackages =
      with pkgs;
      [
        # dart # flutter adds the compatible version
        # freesmlauncher # Overlay from Flake # FIXME: Build Failure
        # reiser4progs # Marked as Broken
        # xfstests # FIXME: Build Failure
        aalib
        aapt
        above
        acl
        acpica-tools
        acpidump-all
        act
        actionlint
        addlicense
        aircrack-ng
        alac
        alsa-plugins
        alsa-tools
        alsa-utils
        alsa-utils-nhlt
        android-backup-extractor
        androidComposition.androidsdk # Custom Composition # Unfree
        ansilove
        anydesk # Unfree
        apfsprogs
        apkeep
        apkleaks
        appimageupdate-qt
        arduino-cli
        arduino-ide
        arduino-language-server
        ascii
        ascii-draw
        ascii-image-converter
        asciicam
        asciinema
        asciinema-agg
        asciiquarium-transparent
        asnmap
        astroterm
        atac
        aurea
        autopsy
        avbroot
        avrdude
        banner
        bash-language-server
        bcachefs-tools
        bcg729
        binutils
        binwalk
        bleachbit
        bluetui
        bluez-alsa
        bluez-tools
        brightnessctl
        btrfs-assistant
        btrfs-heatmap
        btrfs-progs
        bustle
        butt
        calligraphy
        cbonsai
        cdrkit
        celestia
        celt
        certbot-full
        certdump
        cicero-tui
        clang-analyzer
        clang-tools
        clang_22
        clinfo
        cliphist
        cloc
        cmake
        cmake-language-server
        codec2
        codevis
        collision
        compose2nix
        concurrently
        constrict
        cramfsprogs
        cron
        crosspipe
        cryptsetup
        cscope
        ctop
        cups-pk-helper
        cups-printers
        curtail
        cve-bin-tool
        d-spy
        daemon
        darktable
        dbgate
        dconf-editor
        dconf2nix
        ddcui
        ddcutil
        ddrescue
        ddrescueview
        debase
        diffoci
        dig
        disktui
        dive
        dmg2img
        dmidecode
        dnsrecon
        docker-compose-language-service
        docker-language-server
        dosfstools
        dot2tex
        dtui
        dvb-apps
        e2fsprogs
        easyeda2kicad
        ebook2cw
        efibootmgr
        efivar
        egypt
        element
        elf-dissector
        emblem
        esptool
        etherape
        evtest
        evtest-qt
        exfatprogs
        exiftool
        extract-dtb
        f2fs-tools
        fastlane
        fd
        fdk_aac
        fdroidcl
        fdt-viewer
        ferrishot
        ffmpegthumbnailer
        ffpb
        fh
        file
        fileinfo
        flake-checker
        flare-floss
        flatpak-builder
        flatpak-xdg-utils
        flawz
        flowblade
        flutter
        font-manager
        fontfor
        fontpreview
        fork-cleaner
        freecad
        fritzing
        fstl
        gama-tui
        gawk
        gcc
        gdb
        gimp3-with-plugins
        git-big-picture
        git-filter-repo
        git-repo
        github-changelog-generator
        gitlogue
        gittype
        glib
        globe-cli
        gnome-firmware
        gnome-nettool
        gnugrep
        gnumake
        gnused
        gnutar
        gollama
        google-lighthouse
        gource
        gpg-tui
        gpredict
        gpu-viewer
        gradle-completion
        graphviz
        groovy
        gsm
        gtk-vnc
        gtt
        guestfs-tools
        gzip
        hashcat
        hashcat-utils
        hashes
        hdparm
        hexpatch
        hfsprogs
        hieroglyphic
        host
        hstsparser
        hugo
        hurl
        hw-probe
        hydra-check
        hyprgraphics
        hyprland-protocols
        hyprland-qt-support
        hyprland-qtutils
        hyprland-workspaces-tui
        hyprls
        hyprpicker
        hyprshutdown
        hyprtoolkit
        hyprutils
        hyprwayland-scanner
        hyprwire
        i2c-tools
        iaito
        iftop
        ifuse
        indent
        inetutils
        inkscape-with-extensions
        inotify-tools
        interception-tools
        iotop-c
        jfsutils
        jmc2obj
        jmol
        jxrlib
        kernel-hardening-checker
        kernelshark
        kexec-tools
        killall
        kind
        kmod
        kotlin
        kotlin-language-server
        kubectl
        kubernetes-controller-tools
        kubeshark
        lazyjournal
        lazyssh
        libaom
        libarchive
        libde265
        libfreeaptx
        libhsts
        libilbc
        libimobiledevice
        libinput
        liblc3
        libnotify
        libogg
        libopus
        libsecret
        libsixel
        libultrahdr
        libva-utils
        libvpx
        linux-exploit-suggester
        linuxConsoleTools
        lld_22
        llmfit
        llvm_22
        logtop
        lorem
        lsb-release
        lshw
        lsof
        lsscsi
        lssecret
        lvm2
        lynis
        lyto
        lyx
        lzham
        macchanger
        mailcap
        mapscii
        mcaselector
        md-lsp
        md-tui
        meow
        mermaid-cli
        mesa-demos
        metadata
        metadata-cleaner
        mfcuk
        mfoc
        minikube
        mixxx
        mmtui
        monkeys-audio
        mousam
        moxnotify
        mt-st
        mtools
        musescore
        musikcube
        mysqltuner
        nautilus
        nautilus-python
        ncdu
        nemu
        nethogs
        nilfs-utils
        ninja
        nix-diff
        nix-info
        nixmate
        nixpkgs-reviewFull
        nmap
        ntfs3g
        numactl
        numatop
        nurl
        nvme-cli
        obexftp
        oha
        onionshare-gui
        openai-whisper
        openapv
        opencore-amr
        opendmarc
        openh264
        openjpeg
        openobex
        openssl
        oterm
        otree
        paper-clip
        parted
        pbzx
        pciutils
        pdfarranger
        pe-bear
        pev
        pg_top
        pgbadger
        pgmodeler
        pgread
        pipes
        pkg-config
        platformio
        play
        playerctl
        podman-compose
        podman-tui
        poop # POOP = Performance Optimizer Observation Platform
        postgres-language-server
        procps
        profile-cleaner
        progress
        protocol
        protonup-rs
        ps
        psmisc
        python3Packages.tkinter
        qemu-user
        qemu-utils
        qr-backup
        qsstv
        qtrvsim
        qtscrcpy
        radare2
        raider
        rclone-browser
        regex-tui
        rp-pppoe
        rpi-imager
        rpmextract
        rtl-sdr-librtlsdr
        rubyPackages.cocoapods
        runme
        rustc
        sbc
        sbom2dot
        schroedinger
        scope-tui
        screen
        sdrangel
        serial-studio
        share-preview
        shellclear
        sherlock
        sipvicious
        sl
        sleuthkit
        smag
        smartmontools
        sof-tools
        songrec
        sound-theme-freedesktop
        soundconverter
        sox
        spytrap-adb
        sqlit-tui
        sslscan
        steam-run-free
        stellarium
        stenc
        streamlit
        subfinder
        subtitleedit
        svt-av1
        switcheroo
        symlinks
        systemctl-tui
        systemd-lsp
        tdf
        telegraph
        terminaltexteffects
        termscp
        termshark
        texliveFull
        texlivePackages.latexmk
        time
        tpm2-tools
        traceroute
        traitor
        tray-tui
        tree
        treegen
        trufflehog
        trustymail
        tsukae
        ttl
        tutanota-desktop
        udftools
        uefi-firmware-parser
        ugit
        undollar
        unhide
        unhide-gui
        uni2ascii
        unimatrix
        universal-android-debloater # uad-ng
        unix-privesc-check
        unzip
        upnp-router-control
        upscayl
        usbip-ssh
        usbutils
        util-linux
        valgrind
        vex-tui
        video2x
        virt-top
        virt-v2v
        vorbis-tools
        vulkan-caps-viewer
        vulkan-tools
        vulnix
        wafw00f
        wakeonlan
        warehouse
        wavemon
        wayback-machine-archiver
        wayback_machine_downloader
        waycheck
        waydroid-helper
        wayland-utils
        waylevel
        weathr
        webcamize
        webfontkitgenerator
        websocat
        wev
        whatfiles
        which
        whois
        whosthere
        wifitui
        windowtolayer
        wiremix
        wl-clipboard
        wofi-emoji
        wordbook
        worldpainter
        wpprobe
        wvkbd # wvkbd-mobintl
        x2goclient
        xar
        xdg-dbus-proxy
        xdg-user-dirs
        xdg-utils
        xfsdump
        xfsprogs
        xonotic
        xoscope
        xvidcore
        yaml-language-server
        yara-x
        yoshimi
        yq
        yuview
        zenity
        zenmap
        zfs
        zip
        zizmor
        (curlFull.override {
          brotliSupport = true;
          c-aresSupport = true;
          gsaslSupport = true;
          gssSupport = true;
          http2Support = true;
          http3Support = true;
          idnSupport = true;
          opensslSupport = true;
          pslSupport = true;
          rtmpSupport = true;
          scpSupport = true;
          websocketSupport = true;
          zlibSupport = true;
          zstdSupport = true;
        })
        (
          (ffmpeg-full.override {
            withAlsa = false;
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
            withGrayscale = true;
            withGsm = true;
            withHarfbuzz = true;
            withIconv = true;
            withIlbc = true;
            withJack = false;
            withJxl = true;
            withKvazaar = true;
            withLadspa = true;
            withLc3 = true;
            withLcevcdec = true;
            withLcms2 = true;
            withLzma = true;
            withModplug = true;
            withMp3lame = true;
            withMultithread = true;
            withMysofa = true;
            withNetwork = true;
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
            withPulse = false;
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
            withSwscaleAlpha = true;
            withTheora = true;
            withTwolame = true;
            withUavs3d = true;
            withUnfree = true; # Unfree
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
          }).overrideAttrs
          (_: {
            doCheck = false;
          })
        )
        (kicad.override {
          with3d = true;
          withI18n = true;
          withNgspice = true;
          withScripting = true;
          addons = with pkgs.kicadAddons; [
            kikit
            kikit-library
          ];
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
          webuiSupport = true;
        })
        (qmplay2-qt6.override {
          qtVersion = "6";
        })
        (sdrpp.override {
          airspy_source = true;
          airspyhf_source = true;
          audio_sink = true;
          bladerf_source = true;
          file_source = true;
          frequency_manager = true;
          hackrf_source = true;
          limesdr_source = true;
          m17_decoder = true;
          meteor_demodulator = true;
          network_sink = true;
          plutosdr_source = true;
          portaudio_sink = true;
          recorder = true;
          rfspace_source = true;
          rigctl_server = true;
          rtl_sdr_source = true;
          rtl_tcp_source = true;
          scanner = true;
          soapy_source = true;
          spyserver_source = true;
          usrp_source = true;
        })
        (spice-gtk.override {
          withPolkit = true;
        })
        (testdisk-qt.override {
          enableExtFs = true;
          enableNtfs = true;
        }) # qphotorec
        (tigervnc.override {
          waylandSupport = true;
        })
        (tor-browser.override {
          audioSupport = true;
          libnotifySupport = true;
          libvaSupport = true;
          mediaSupport = true;
          pipewireSupport = true;
          pulseaudioSupport = false;
          waylandSupport = true;
        })
        (tree-sitter.override {
          webUISupport = false; # FIXME: Build Failure
        })
        (ventoy-full-gtk.override {
          withExt4 = true;
          withNtfs = true;
          withXfs = true;
        })
        (virt-viewer.override {
          spiceSupport = true;
        })
        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })
        (wget2.override {
          sslSupport = true;
        })
        config.hardware.firmware
        config.home-manager.users.root.programs.dircolors.package
        config.home-manager.users.root.services.udiskie.package
        config.services.phpfpm.phpPackage
      ]
      ++ config.boot.extraModulePackages
      ++ config.fonts.packages
      ++ config.hardware.graphics.extraPackages
      ++ config.hardware.graphics.extraPackages32
      ++ config.hardware.sane.extraBackends
      ++ config.home-manager.users.root.programs.gh.extensions
      ++ config.home-manager.users.root.programs.lutris.extraPackages
      ++ config.home-manager.users.root.programs.lutris.winePackages
      ++ config.home-manager.users.root.programs.zed-editor.extraPackages
      ++ config.i18n.inputMethod.fcitx5.addons
      ++ config.programs.bat.extraPackages
      ++ config.programs.obs-studio.plugins
      ++ config.services.cockpit.plugins
      ++ config.services.pipewire.extraLv2Packages
      ++ config.services.printing.drivers
      ++ config.services.udev.packages
      ++ config.virtualisation.libvirtd.qemu.vhostUserPackages
      ++ config.virtualisation.podman.extraPackages
      ++ config.virtualisation.podman.extraRuntimes
      ++ config.xdg.portal.extraPortals
      ++ (with ghidra-extensions; [
        findcrypt
        ghidra-delinker-extension
        ghidra-golanganalyzerextension
        ghidraninja-ghidra-scripts
        gnudisassembler
        lightkeeper
        machinelearning
        ret-sync
        sleighdevtools
        wasm
      ])
      ++ (with gst_all_1; [
        (gst-libav.override {
          enableDocumentation = true;
        })
        (gst-plugins-bad.override {
          ajaSupport = true;
          bluezSupport = true;
          enableDocumentation = true;
          enableGplPlugins = true;
          enableZbar = true;
          guiSupport = true;
          ldacbtSupport = true;
          microdnsSupport = true;
          opencvSupport = true;
          openh264Support = true;
          webrtcAudioProcessingSupport = true;
        })
        (gst-plugins-base.override {
          enableAlsa = false;
          enableCdparanoia = true;
          enableDocumentation = true;
          enableWayland = true;
        })
        (gst-plugins-good.override {
          enableDocumentation = true;
          enableJack = false;
          enableWayland = true;
          gtkSupport = true;
          qt6Support = true;
        })
        (gst-plugins-ugly.override {
          enableDocumentation = true;
          enableGplPlugins = true;
        })
        (gst-vaapi.override {
          enableDocumentation = true;
        })
        (gstreamer.override {
          enableDocumentation = true;
        })
      ])
      ++ (with kubernetes-helmPlugins; [
        helm-diff
        helm-git
        helm-schema
        helm-secrets
      ])
      ++ (with linphonePackages; [
        bc-decaf
        bc-ispell
        bc-mbedtls
        bc-soci
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
      ++ (with tree-sitter-grammars; [
        tree-sitter-awk
        tree-sitter-bash
        tree-sitter-bibtex
        tree-sitter-c
        tree-sitter-cmake
        tree-sitter-comment
        tree-sitter-cpp
        tree-sitter-css
        tree-sitter-csv
        tree-sitter-dart
        tree-sitter-diff
        tree-sitter-dockerfile
        tree-sitter-dot
        tree-sitter-dtd
        tree-sitter-git-config
        tree-sitter-git-rebase
        tree-sitter-gitattributes
        tree-sitter-gitcommit
        tree-sitter-gitignore
        tree-sitter-graphql
        tree-sitter-hosts
        tree-sitter-html
        tree-sitter-http
        tree-sitter-hurl
        tree-sitter-hyprlang
        tree-sitter-ini
        tree-sitter-javascript
        tree-sitter-jq
        tree-sitter-json
        tree-sitter-kotlin
        tree-sitter-latex
        tree-sitter-ld
        tree-sitter-llvm
        tree-sitter-log
        tree-sitter-lua
        tree-sitter-mail
        tree-sitter-make
        tree-sitter-markdown
        tree-sitter-markdown-inline
        tree-sitter-mermaid
        tree-sitter-nix
        tree-sitter-passwd
        tree-sitter-pem
        tree-sitter-php
        tree-sitter-powershell
        tree-sitter-python
        tree-sitter-query
        tree-sitter-regex
        tree-sitter-smali
        tree-sitter-sql
        tree-sitter-sshclientconfig
        tree-sitter-todotxt
        tree-sitter-toml
        tree-sitter-xml
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
      ]);

    wordlist = {
      enable = true;
      lists = {
        WORDLISTS = [
          "${config.home-manager.users.root.programs.keepassxc.package}/share/keepassxc/wordlists/eff_large.wordlist"
          "${pkgs.rockyou}/share/wordlists/rockyou.txt"
          # (builtins.toFile "extra-wordlist" '''')
        ];
      };
    };

    variables = {
      ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk"; # Unfree
      ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk"; # Unfree
      ANDROID_NDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk/ndk-bundle"; # Unfree

      LD_LIBRARY_PATH = lib.mkForce "${
        pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            sqlite
          ]
        )
      }:$LD_LIBRARY_PATH";

      CHROME_EXECUTABLE = "${config.home-manager.users.root.programs.chromium.package}/bin/brave";
    };

    sessionVariables = {
      NIXOS_OZONE_WL = 1;

      ADW_DISABLE_PORTAL = 1;

      XCURSOR_THEME = config.home-manager.users.root.home.pointerCursor.name;
      XCURSOR_SIZE = config.home-manager.users.root.home.pointerCursor.size;
    };

    shellAliases = {
      unbind_i8042_driver = "sudo sh -c 'echo -n \"i8042\" > /sys/bus/platform/drivers/i8042/unbind'";
      bind_i8042_driver = "sudo sh -c 'echo -n \"i8042\" > /sys/bus/platform/drivers/i8042/bind'";

      clean_upgrade = "sudo nh clean all && sudo nix-store --verify --check-contents --repair && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
    };

    # extraInit = '''';
    # loginShellInit = '''';
    # shellInit = '''';
    # interactiveShellInit = '''';

    enableDebugInfo = false;
  };

  xdg = {
    sounds.enable = true;
    icons.enable = true;
    menus.enable = true;

    autostart.enable = true;

    terminal-exec = {
      enable = true;
      package = pkgs.xdg-terminal-exec;

      settings = {
        default = [
          "foot.desktop"
        ];
      };
    };

    portal = {
      enable = true;
      extraPortals = with pkgs; [
        config.programs.hyprland.portalPackage
        xdg-desktop-portal-gtk
      ];

      xdgOpenUsePortal = true;

      config = {
        common = {
          default = [
            "hyprland"
            "gtk"
          ];

          "org.freedesktop.impl.portal.FileChooser" = [
            "gtk"
          ];

          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };

      };
    };

    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      # https://www.iana.org/assignments/media-types/media-types.xhtml
      defaultApplications = {
        "inode/directory" = "yazi.desktop";

        "text/1d-interleaved-parityfec" = "dev.zed.Zed.desktop";
        "text/cache-manifest" = "dev.zed.Zed.desktop";
        "text/calendar" = "dev.zed.Zed.desktop";
        "text/cql" = "dev.zed.Zed.desktop";
        "text/cql-expression" = "dev.zed.Zed.desktop";
        "text/cql-identifier" = "dev.zed.Zed.desktop";
        "text/css" = "dev.zed.Zed.desktop";
        "text/csv" = "dev.zed.Zed.desktop";
        "text/csv-schema" = "dev.zed.Zed.desktop";
        "text/directory" = "dev.zed.Zed.desktop";
        "text/dns" = "dev.zed.Zed.desktop";
        "text/ecmascript" = "dev.zed.Zed.desktop";
        "text/encaprtp" = "dev.zed.Zed.desktop";
        "text/enriched" = "dev.zed.Zed.desktop";
        "text/fhirpath" = "dev.zed.Zed.desktop";
        "text/flexfec" = "dev.zed.Zed.desktop";
        "text/fwdred" = "dev.zed.Zed.desktop";
        "text/gff3" = "dev.zed.Zed.desktop";
        "text/grammar-ref-list" = "dev.zed.Zed.desktop";
        "text/hl7v2" = "dev.zed.Zed.desktop";
        "text/html" = "dev.zed.Zed.desktop";
        "text/javascript" = "dev.zed.Zed.desktop";
        "text/jcr-cnd" = "dev.zed.Zed.desktop";
        "text/markdown" = "dev.zed.Zed.desktop";
        "text/mizar" = "dev.zed.Zed.desktop";
        "text/n3" = "dev.zed.Zed.desktop";
        "text/org" = "dev.zed.Zed.desktop";
        "text/parameters" = "dev.zed.Zed.desktop";
        "text/parityfec" = "dev.zed.Zed.desktop";
        "text/plain" = "dev.zed.Zed.desktop";
        "text/provenance-notation" = "dev.zed.Zed.desktop";
        "text/prs.fallenstein.rst" = "dev.zed.Zed.desktop";
        "text/prs.lines.tag" = "dev.zed.Zed.desktop";
        "text/prs.prop.logic" = "dev.zed.Zed.desktop";
        "text/prs.texi" = "dev.zed.Zed.desktop";
        "text/raptorfec" = "dev.zed.Zed.desktop";
        "text/RED" = "dev.zed.Zed.desktop";
        "text/rfc822-headers" = "dev.zed.Zed.desktop";
        "text/richtext" = "dev.zed.Zed.desktop";
        "text/rtf" = "dev.zed.Zed.desktop";
        "text/rtp-enc-aescm128" = "dev.zed.Zed.desktop";
        "text/rtploopback" = "dev.zed.Zed.desktop";
        "text/rtx" = "dev.zed.Zed.desktop";
        "text/SGML" = "dev.zed.Zed.desktop";
        "text/shaclc" = "dev.zed.Zed.desktop";
        "text/shex" = "dev.zed.Zed.desktop";
        "text/spdx" = "dev.zed.Zed.desktop";
        "text/strings" = "dev.zed.Zed.desktop";
        "text/t140" = "dev.zed.Zed.desktop";
        "text/tab-separated-values" = "dev.zed.Zed.desktop";
        "text/troff" = "dev.zed.Zed.desktop";
        "text/turtle" = "dev.zed.Zed.desktop";
        "text/ulpfec" = "dev.zed.Zed.desktop";
        "text/uri-list" = "dev.zed.Zed.desktop";
        "text/vcard" = "dev.zed.Zed.desktop";
        "text/vnd.a" = "dev.zed.Zed.desktop";
        "text/vnd.abc" = "dev.zed.Zed.desktop";
        "text/vnd.ascii-art" = "dev.zed.Zed.desktop";
        "text/vnd.curl" = "dev.zed.Zed.desktop";
        "text/vnd.debian.copyright" = "dev.zed.Zed.desktop";
        "text/vnd.DMClientScript" = "dev.zed.Zed.desktop";
        "text/vnd.dvb.subtitle" = "dev.zed.Zed.desktop";
        "text/vnd.esmertec.theme-descriptor" = "dev.zed.Zed.desktop";
        "text/vnd.exchangeable" = "dev.zed.Zed.desktop";
        "text/vnd.familysearch.gedcom" = "dev.zed.Zed.desktop";
        "text/vnd.ficlab.flt" = "dev.zed.Zed.desktop";
        "text/vnd.fly" = "dev.zed.Zed.desktop";
        "text/vnd.fmi.flexstor" = "dev.zed.Zed.desktop";
        "text/vnd.gml" = "dev.zed.Zed.desktop";
        "text/vnd.graphviz" = "dev.zed.Zed.desktop";
        "text/vnd.hans" = "dev.zed.Zed.desktop";
        "text/vnd.hgl" = "dev.zed.Zed.desktop";
        "text/vnd.in3d.3dml" = "dev.zed.Zed.desktop";
        "text/vnd.in3d.spot" = "dev.zed.Zed.desktop";
        "text/vnd.IPTC.NewsML" = "dev.zed.Zed.desktop";
        "text/vnd.IPTC.NITF" = "dev.zed.Zed.desktop";
        "text/vnd.latex-z" = "dev.zed.Zed.desktop";
        "text/vnd.motorola.reflex" = "dev.zed.Zed.desktop";
        "text/vnd.ms-mediapackage" = "dev.zed.Zed.desktop";
        "text/vnd.net2phone.commcenter.command" = "dev.zed.Zed.desktop";
        "text/vnd.radisys.msml-basic-layout" = "dev.zed.Zed.desktop";
        "text/vnd.senx.warpscript" = "dev.zed.Zed.desktop";
        "text/vnd.si.uricatalogue" = "dev.zed.Zed.desktop";
        "text/vnd.sosi" = "dev.zed.Zed.desktop";
        "text/vnd.sun.j2me.app-descriptor" = "dev.zed.Zed.desktop";
        "text/vnd.trolltech.linguist" = "dev.zed.Zed.desktop";
        "text/vnd.typst" = "dev.zed.Zed.desktop";
        "text/vnd.vcf" = "dev.zed.Zed.desktop";
        "text/vnd.wap.si" = "dev.zed.Zed.desktop";
        "text/vnd.wap.sl" = "dev.zed.Zed.desktop";
        "text/vnd.wap.wml" = "dev.zed.Zed.desktop";
        "text/vnd.wap.wmlscript" = "dev.zed.Zed.desktop";
        "text/vnd.zoo.kcl" = "dev.zed.Zed.desktop";
        "text/vtt" = "dev.zed.Zed.desktop";
        "text/wgsl" = "dev.zed.Zed.desktop";
        "text/xml" = "dev.zed.Zed.desktop";
        "text/xml-external-parsed-entity" = "dev.zed.Zed.desktop";

        "image/aces" = "imv.desktop";
        "image/apng" = "imv.desktop";
        "image/avci" = "imv.desktop";
        "image/avcs" = "imv.desktop";
        "image/avif" = "imv.desktop";
        "image/bmp" = "imv.desktop";
        "image/cgm" = "imv.desktop";
        "image/dicom-rle" = "imv.desktop";
        "image/dpx" = "imv.desktop";
        "image/emf" = "imv.desktop";
        "image/fits" = "imv.desktop";
        "image/g3fax" = "imv.desktop";
        "image/gif" = "imv.desktop";
        "image/heic-sequence" = "imv.desktop";
        "image/heic" = "imv.desktop";
        "image/heif-sequence" = "imv.desktop";
        "image/heif" = "imv.desktop";
        "image/hej2k" = "imv.desktop";
        "image/hsj2" = "imv.desktop";
        "image/ief" = "imv.desktop";
        "image/j2c" = "imv.desktop";
        "image/jaii" = "imv.desktop";
        "image/jais" = "imv.desktop";
        "image/jls" = "imv.desktop";
        "image/jp2" = "imv.desktop";
        "image/jpeg" = "imv.desktop";
        "image/jph" = "imv.desktop";
        "image/jphc" = "imv.desktop";
        "image/jpm" = "imv.desktop";
        "image/jpx" = "imv.desktop";
        "image/jxl" = "imv.desktop";
        "image/jxr" = "imv.desktop";
        "image/jxrA" = "imv.desktop";
        "image/jxrS" = "imv.desktop";
        "image/jxs" = "imv.desktop";
        "image/jxsc" = "imv.desktop";
        "image/jxsi" = "imv.desktop";
        "image/jxss" = "imv.desktop";
        "image/ktx" = "imv.desktop";
        "image/ktx2" = "imv.desktop";
        "image/naplps" = "imv.desktop";
        "image/png" = "imv.desktop";
        "image/prs.btif" = "imv.desktop";
        "image/prs.pti" = "imv.desktop";
        "image/pwg-raster" = "imv.desktop";
        "image/svg+xml" = "imv.desktop";
        "image/t38" = "imv.desktop";
        "image/tiff-fx" = "imv.desktop";
        "image/tiff" = "imv.desktop";
        "image/vnd.adobe.photoshop" = "imv.desktop";
        "image/vnd.airzip.accelerator.azv" = "imv.desktop";
        "image/vnd.blockfact.facti" = "imv.desktop";
        "image/vnd.clip" = "imv.desktop";
        "image/vnd.cns.inf2" = "imv.desktop";
        "image/vnd.dece.graphic" = "imv.desktop";
        "image/vnd.djvu" = "imv.desktop";
        "image/vnd.dvb.subtitle" = "imv.desktop";
        "image/vnd.dwg" = "imv.desktop";
        "image/vnd.dxf" = "imv.desktop";
        "image/vnd.fastbidsheet" = "imv.desktop";
        "image/vnd.fpx" = "imv.desktop";
        "image/vnd.fst" = "imv.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "imv.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "imv.desktop";
        "image/vnd.globalgraphics.pgb" = "imv.desktop";
        "image/vnd.microsoft.icon" = "imv.desktop";
        "image/vnd.mix" = "imv.desktop";
        "image/vnd.mozilla.apng" = "imv.desktop";
        "image/vnd.ms-modi" = "imv.desktop";
        "image/vnd.net-fpx" = "imv.desktop";
        "image/vnd.pco.b16" = "imv.desktop";
        "image/vnd.radiance" = "imv.desktop";
        "image/vnd.sealed.png" = "imv.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "imv.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "imv.desktop";
        "image/vnd.svf" = "imv.desktop";
        "image/vnd.tencent.tap" = "imv.desktop";
        "image/vnd.valve.source.texture" = "imv.desktop";
        "image/vnd.wap.wbmp" = "imv.desktop";
        "image/vnd.xiff" = "imv.desktop";
        "image/vnd.zbrush.pcx" = "imv.desktop";
        "image/webp" = "imv.desktop";
        "image/wmf" = "imv.desktop";
        "image/x-emf" = "imv.desktop";
        "image/x-wmf" = "imv.desktop";

        "audio/1d-interleaved-parityfec" = "QMPlay2.desktop";
        "audio/32kadpcm" = "QMPlay2.desktop";
        "audio/3gpp" = "QMPlay2.desktop";
        "audio/3gpp2" = "QMPlay2.desktop";
        "audio/aac" = "QMPlay2.desktop";
        "audio/ac3" = "QMPlay2.desktop";
        "audio/AMR-WB" = "QMPlay2.desktop";
        "audio/amr-wb+" = "QMPlay2.desktop";
        "audio/AMR" = "QMPlay2.desktop";
        "audio/aptx" = "QMPlay2.desktop";
        "audio/asc" = "QMPlay2.desktop";
        "audio/ATRAC-ADVANCED-LOSSLESS" = "QMPlay2.desktop";
        "audio/ATRAC-X" = "QMPlay2.desktop";
        "audio/ATRAC3" = "QMPlay2.desktop";
        "audio/basic" = "QMPlay2.desktop";
        "audio/BV16" = "QMPlay2.desktop";
        "audio/BV32" = "QMPlay2.desktop";
        "audio/clearmode" = "QMPlay2.desktop";
        "audio/CN" = "QMPlay2.desktop";
        "audio/DAT12" = "QMPlay2.desktop";
        "audio/dls" = "QMPlay2.desktop";
        "audio/dsr-es201108" = "QMPlay2.desktop";
        "audio/dsr-es202050" = "QMPlay2.desktop";
        "audio/dsr-es202211" = "QMPlay2.desktop";
        "audio/dsr-es202212" = "QMPlay2.desktop";
        "audio/DV" = "QMPlay2.desktop";
        "audio/DVI4" = "QMPlay2.desktop";
        "audio/eac3" = "QMPlay2.desktop";
        "audio/encaprtp" = "QMPlay2.desktop";
        "audio/EVRC-QCP" = "QMPlay2.desktop";
        "audio/EVRC" = "QMPlay2.desktop";
        "audio/EVRC0" = "QMPlay2.desktop";
        "audio/EVRC1" = "QMPlay2.desktop";
        "audio/EVRCB" = "QMPlay2.desktop";
        "audio/EVRCB0" = "QMPlay2.desktop";
        "audio/EVRCB1" = "QMPlay2.desktop";
        "audio/EVRCNW" = "QMPlay2.desktop";
        "audio/EVRCNW0" = "QMPlay2.desktop";
        "audio/EVRCNW1" = "QMPlay2.desktop";
        "audio/EVRCWB" = "QMPlay2.desktop";
        "audio/EVRCWB0" = "QMPlay2.desktop";
        "audio/EVRCWB1" = "QMPlay2.desktop";
        "audio/EVS" = "QMPlay2.desktop";
        "audio/flac" = "QMPlay2.desktop";
        "audio/flexfec" = "QMPlay2.desktop";
        "audio/fwdred" = "QMPlay2.desktop";
        "audio/G711-0" = "QMPlay2.desktop";
        "audio/G719" = "QMPlay2.desktop";
        "audio/G722" = "QMPlay2.desktop";
        "audio/G7221" = "QMPlay2.desktop";
        "audio/G723" = "QMPlay2.desktop";
        "audio/G726-16" = "QMPlay2.desktop";
        "audio/G726-24" = "QMPlay2.desktop";
        "audio/G726-32" = "QMPlay2.desktop";
        "audio/G726-40" = "QMPlay2.desktop";
        "audio/G728" = "QMPlay2.desktop";
        "audio/G729" = "QMPlay2.desktop";
        "audio/G7291" = "QMPlay2.desktop";
        "audio/G729D" = "QMPlay2.desktop";
        "audio/G729E" = "QMPlay2.desktop";
        "audio/GSM-EFR" = "QMPlay2.desktop";
        "audio/GSM-HR-08" = "QMPlay2.desktop";
        "audio/GSM" = "QMPlay2.desktop";
        "audio/iLBC" = "QMPlay2.desktop";
        "audio/ip-mr_v2.5" = "QMPlay2.desktop";
        "audio/L16" = "QMPlay2.desktop";
        "audio/L20" = "QMPlay2.desktop";
        "audio/L24" = "QMPlay2.desktop";
        "audio/L8" = "QMPlay2.desktop";
        "audio/LPC" = "QMPlay2.desktop";
        "audio/matroska" = "QMPlay2.desktop";
        "audio/MELP" = "QMPlay2.desktop";
        "audio/MELP1200" = "QMPlay2.desktop";
        "audio/MELP2400" = "QMPlay2.desktop";
        "audio/MELP600" = "QMPlay2.desktop";
        "audio/mhas" = "QMPlay2.desktop";
        "audio/midi-clip" = "QMPlay2.desktop";
        "audio/mobile-xmf" = "QMPlay2.desktop";
        "audio/mp4" = "QMPlay2.desktop";
        "audio/MP4A-LATM" = "QMPlay2.desktop";
        "audio/mpa-robust" = "QMPlay2.desktop";
        "audio/MPA" = "QMPlay2.desktop";
        "audio/mpeg" = "QMPlay2.desktop";
        "audio/mpeg4-generic" = "QMPlay2.desktop";
        "audio/ogg" = "QMPlay2.desktop";
        "audio/opus" = "QMPlay2.desktop";
        "audio/parityfec" = "QMPlay2.desktop";
        "audio/PCMA-WB" = "QMPlay2.desktop";
        "audio/PCMA" = "QMPlay2.desktop";
        "audio/PCMU-WB" = "QMPlay2.desktop";
        "audio/PCMU" = "QMPlay2.desktop";
        "audio/prs.sid" = "QMPlay2.desktop";
        "audio/QCELP" = "QMPlay2.desktop";
        "audio/raptorfec" = "QMPlay2.desktop";
        "audio/RED" = "QMPlay2.desktop";
        "audio/rtp-enc-aescm128" = "QMPlay2.desktop";
        "audio/rtp-midi" = "QMPlay2.desktop";
        "audio/rtploopback" = "QMPlay2.desktop";
        "audio/rtx" = "QMPlay2.desktop";
        "audio/scip" = "QMPlay2.desktop";
        "audio/SMV-QCP" = "QMPlay2.desktop";
        "audio/SMV" = "QMPlay2.desktop";
        "audio/SMV0" = "QMPlay2.desktop";
        "audio/sofa" = "QMPlay2.desktop";
        "audio/soundfont" = "QMPlay2.desktop";
        "audio/sp-midi" = "QMPlay2.desktop";
        "audio/speex" = "QMPlay2.desktop";
        "audio/t140c" = "QMPlay2.desktop";
        "audio/t38" = "QMPlay2.desktop";
        "audio/telephone-event" = "QMPlay2.desktop";
        "audio/TETRA_ACELP_BB" = "QMPlay2.desktop";
        "audio/TETRA_ACELP" = "QMPlay2.desktop";
        "audio/tone" = "QMPlay2.desktop";
        "audio/TSVCIS" = "QMPlay2.desktop";
        "audio/UEMCLIP" = "QMPlay2.desktop";
        "audio/ulpfec" = "QMPlay2.desktop";
        "audio/usac" = "QMPlay2.desktop";
        "audio/VDVI" = "QMPlay2.desktop";
        "audio/VMR-WB" = "QMPlay2.desktop";
        "audio/vnd.3gpp.iufp" = "QMPlay2.desktop";
        "audio/vnd.4SB" = "QMPlay2.desktop";
        "audio/vnd.audiokoz" = "QMPlay2.desktop";
        "audio/vnd.blockfact.facta" = "QMPlay2.desktop";
        "audio/vnd.CELP" = "QMPlay2.desktop";
        "audio/vnd.cisco.nse" = "QMPlay2.desktop";
        "audio/vnd.cmles.radio-events" = "QMPlay2.desktop";
        "audio/vnd.cns.anp1" = "QMPlay2.desktop";
        "audio/vnd.cns.inf1" = "QMPlay2.desktop";
        "audio/vnd.dece.audio" = "QMPlay2.desktop";
        "audio/vnd.digital-winds" = "QMPlay2.desktop";
        "audio/vnd.dlna.adts" = "QMPlay2.desktop";
        "audio/vnd.dolby.heaac.1" = "QMPlay2.desktop";
        "audio/vnd.dolby.heaac.2" = "QMPlay2.desktop";
        "audio/vnd.dolby.mlp" = "QMPlay2.desktop";
        "audio/vnd.dolby.mps" = "QMPlay2.desktop";
        "audio/vnd.dolby.pl2" = "QMPlay2.desktop";
        "audio/vnd.dolby.pl2x" = "QMPlay2.desktop";
        "audio/vnd.dolby.pl2z" = "QMPlay2.desktop";
        "audio/vnd.dolby.pulse.1" = "QMPlay2.desktop";
        "audio/vnd.dra" = "QMPlay2.desktop";
        "audio/vnd.dts.hd" = "QMPlay2.desktop";
        "audio/vnd.dts.uhd" = "QMPlay2.desktop";
        "audio/vnd.dts" = "QMPlay2.desktop";
        "audio/vnd.dvb.file" = "QMPlay2.desktop";
        "audio/vnd.everad.plj" = "QMPlay2.desktop";
        "audio/vnd.hns.audio" = "QMPlay2.desktop";
        "audio/vnd.lucent.voice" = "QMPlay2.desktop";
        "audio/vnd.ms-playready.media.pya" = "QMPlay2.desktop";
        "audio/vnd.nokia.mobile-xmf" = "QMPlay2.desktop";
        "audio/vnd.nortel.vbk" = "QMPlay2.desktop";
        "audio/vnd.nuera.ecelp4800" = "QMPlay2.desktop";
        "audio/vnd.nuera.ecelp7470" = "QMPlay2.desktop";
        "audio/vnd.nuera.ecelp9600" = "QMPlay2.desktop";
        "audio/vnd.octel.sbc" = "QMPlay2.desktop";
        "audio/vnd.presonus.multitrack" = "QMPlay2.desktop";
        "audio/vnd.qcelp" = "QMPlay2.desktop";
        "audio/vnd.rhetorex.32kadpcm" = "QMPlay2.desktop";
        "audio/vnd.rip" = "QMPlay2.desktop";
        "audio/vnd.sealedmedia.softseal.mpeg" = "QMPlay2.desktop";
        "audio/vnd.vmx.cvsd" = "QMPlay2.desktop";
        "audio/vorbis-config" = "QMPlay2.desktop";
        "audio/vorbis" = "QMPlay2.desktop";

        "video/1d-interleaved-parityfec" = "QMPlay2.desktop";
        "video/3gpp-tt" = "QMPlay2.desktop";
        "video/3gpp" = "QMPlay2.desktop";
        "video/3gpp2" = "QMPlay2.desktop";
        "video/AV1" = "QMPlay2.desktop";
        "video/BMPEG" = "QMPlay2.desktop";
        "video/BT656" = "QMPlay2.desktop";
        "video/CelB" = "QMPlay2.desktop";
        "video/DV" = "QMPlay2.desktop";
        "video/encaprtp" = "QMPlay2.desktop";
        "video/evc" = "QMPlay2.desktop";
        "video/FFV1" = "QMPlay2.desktop";
        "video/flexfec" = "QMPlay2.desktop";
        "video/H261" = "QMPlay2.desktop";
        "video/H263-1998" = "QMPlay2.desktop";
        "video/H263-2000" = "QMPlay2.desktop";
        "video/H263" = "QMPlay2.desktop";
        "video/H264-RCDO" = "QMPlay2.desktop";
        "video/H264-SVC" = "QMPlay2.desktop";
        "video/H264" = "QMPlay2.desktop";
        "video/H265" = "QMPlay2.desktop";
        "video/H266" = "QMPlay2.desktop";
        "video/iso.segment" = "QMPlay2.desktop";
        "video/JPEG" = "QMPlay2.desktop";
        "video/jpeg2000-scl" = "QMPlay2.desktop";
        "video/jpeg2000" = "QMPlay2.desktop";
        "video/jxsv" = "QMPlay2.desktop";
        "video/lottie+json" = "QMPlay2.desktop";
        "video/matroska-3d" = "QMPlay2.desktop";
        "video/matroska" = "QMPlay2.desktop";
        "video/mj2" = "QMPlay2.desktop";
        "video/MP1S" = "QMPlay2.desktop";
        "video/MP2P" = "QMPlay2.desktop";
        "video/MP2T" = "QMPlay2.desktop";
        "video/mp4" = "QMPlay2.desktop";
        "video/MP4V-ES" = "QMPlay2.desktop";
        "video/mpeg" = "QMPlay2.desktop";
        "video/mpeg4-generic" = "QMPlay2.desktop";
        "video/MPV" = "QMPlay2.desktop";
        "video/nv" = "QMPlay2.desktop";
        "video/ogg" = "QMPlay2.desktop";
        "video/parityfec" = "QMPlay2.desktop";
        "video/pointer" = "QMPlay2.desktop";
        "video/quicktime" = "QMPlay2.desktop";
        "video/raptorfec" = "QMPlay2.desktop";
        "video/raw" = "QMPlay2.desktop";
        "video/rtp-enc-aescm128" = "QMPlay2.desktop";
        "video/rtploopback" = "QMPlay2.desktop";
        "video/rtx" = "QMPlay2.desktop";
        "video/scip" = "QMPlay2.desktop";
        "video/smpte291" = "QMPlay2.desktop";
        "video/SMPTE292M" = "QMPlay2.desktop";
        "video/ulpfec" = "QMPlay2.desktop";
        "video/vc1" = "QMPlay2.desktop";
        "video/vc2" = "QMPlay2.desktop";
        "video/vnd.blockfact.factv" = "QMPlay2.desktop";
        "video/vnd.CCTV" = "QMPlay2.desktop";
        "video/vnd.dece.hd" = "QMPlay2.desktop";
        "video/vnd.dece.mobile" = "QMPlay2.desktop";
        "video/vnd.dece.mp4" = "QMPlay2.desktop";
        "video/vnd.dece.pd" = "QMPlay2.desktop";
        "video/vnd.dece.sd" = "QMPlay2.desktop";
        "video/vnd.dece.video" = "QMPlay2.desktop";
        "video/vnd.directv.mpeg-tts" = "QMPlay2.desktop";
        "video/vnd.directv.mpeg" = "QMPlay2.desktop";
        "video/vnd.dlna.mpeg-tts" = "QMPlay2.desktop";
        "video/vnd.dvb.file" = "QMPlay2.desktop";
        "video/vnd.fvt" = "QMPlay2.desktop";
        "video/vnd.hns.video" = "QMPlay2.desktop";
        "video/vnd.iptvforum.1dparityfec-1010" = "QMPlay2.desktop";
        "video/vnd.iptvforum.1dparityfec-2005" = "QMPlay2.desktop";
        "video/vnd.iptvforum.2dparityfec-1010" = "QMPlay2.desktop";
        "video/vnd.iptvforum.2dparityfec-2005" = "QMPlay2.desktop";
        "video/vnd.iptvforum.ttsavc" = "QMPlay2.desktop";
        "video/vnd.iptvforum.ttsmpeg2" = "QMPlay2.desktop";
        "video/vnd.motorola.video" = "QMPlay2.desktop";
        "video/vnd.motorola.videop" = "QMPlay2.desktop";
        "video/vnd.mpegurl" = "QMPlay2.desktop";
        "video/vnd.ms-playready.media.pyv" = "QMPlay2.desktop";
        "video/vnd.nokia.interleaved-multimedia" = "QMPlay2.desktop";
        "video/vnd.nokia.mp4vr" = "QMPlay2.desktop";
        "video/vnd.nokia.videovoip" = "QMPlay2.desktop";
        "video/vnd.objectvideo" = "QMPlay2.desktop";
        "video/vnd.planar" = "QMPlay2.desktop";
        "video/vnd.radgamettools.bink" = "QMPlay2.desktop";
        "video/vnd.radgamettools.smacker" = "QMPlay2.desktop";
        "video/vnd.sealed.mpeg1" = "QMPlay2.desktop";
        "video/vnd.sealed.mpeg4" = "QMPlay2.desktop";
        "video/vnd.sealed.swf" = "QMPlay2.desktop";
        "video/vnd.sealedmedia.softseal.mov" = "QMPlay2.desktop";
        "video/vnd.uvvu.mp4" = "QMPlay2.desktop";
        "video/vnd.vivo" = "QMPlay2.desktop";
        "video/vnd.youtube.yt" = "QMPlay2.desktop";
        "video/VP8" = "QMPlay2.desktop";
        "video/VP9" = "QMPlay2.desktop";
        "video/x-matroska" = "QMPlay2.desktop"; # https://mime.wcode.net/mkv

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

        "application/pdf" = "com.brave.Browser.desktop";

        "font/collection" = "com.github.FontManager.FontViewer.desktop";
        "font/otf" = "com.github.FontManager.FontViewer.desktop";
        "font/sfnt" = "com.github.FontManager.FontViewer.desktop";
        "font/ttf" = "com.github.FontManager.FontViewer.desktop";
        "font/woff" = "com.github.FontManager.FontViewer.desktop";
        "font/woff2" = "com.github.FontManager.FontViewer.desktop";

        "application/gzip" = "yazi.desktop";
        "application/vnd.rar" = "yazi.desktop";
        "application/x-7z-compressed" = "yazi.desktop";
        "application/x-arj" = "yazi.desktop";
        "application/x-bzip2" = "yazi.desktop";
        "application/x-gtar" = "yazi.desktop";
        "application/x-rar-compressed " = "yazi.desktop"; # More common than "application/vnd.rar"
        "application/x-tar" = "yazi.desktop";
        "application/zip" = "yazi.desktop";

        "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
        "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";

        "x-scheme-handler/http" = "com.brave.Browser.desktop";
        "x-scheme-handler/https" = "com.brave.Browser.desktop";

        "x-scheme-handler/mailto" = "tutanota-desktop.desktop";
      };
    };
  };

  gtk.iconCache.enable = true;

  qt = {
    enable = true;
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

      cache.enable = true;
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

    defaultUserShell = (
      pkgs.bash.override {
        interactive = true;
      }
    );

    motd = "Welcome to ${config.networking.fqdn}";

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
        "disk"
        "floppy"
        "fwupd-refresh"
        "greeter"
        "i2c"
        "input"
        "kvm"
        "libvirtd"
        "lp"
        "lpadmin"
        "networkmanager"
        "nm-openvpn"
        "pipewire"
        "plugdev"
        "podman"
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
      ];

      useDefaultShell = true;
    };
  };

  catppuccin = {
    enable = true;

    enableReleaseCheck = true;
    cache.enable = true;

    flavor = "mocha";
    accent = "lavender";

    grub = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
    };

    tty = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
    };

    plymouth.enable = false;

    cursors = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;
    };

    gtk.icon.enable = false;

    fcitx5 = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;

      enableRounded = true;
    };
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;

    backupFileExtension = "old";

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

          preferXdgDirectories = true;

          pointerCursor = {
            name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
            size = builtins.floor (design_factor * 1.50); # 24

            hyprcursor = {
              enable = true;
              size = config.home-manager.users.root.home.pointerCursor.size;
            };

            gtk = {
              enable = true;
              size = config.home-manager.users.root.home.pointerCursor.size;
            };

            x11.enable = false;

            dotIcons.enable = true;
          };

          # sessionSearchVariables = { };

          activation = {
            copyOnlyOfficeFonts = ''
              mkdir -p $HOME/.local/share/fonts/
              cp -f /var/lib/onlyoffice-fonts/* $HOME/.local/share/fonts/ || true
              ${pkgs.fontconfig}/bin/fc-cache -f $HOME/.local/share/fonts/
            '';
          };

          enableDebugInfo = false;

          stateVersion = config.system.stateVersion;
        };

        wayland.windowManager.hyprland = {
          enable = config.programs.hyprland.enable;
          package = config.programs.hyprland.package;

          systemd = {
            enable = false;

            enableXdgAutostart = true;

            variables = [
              "--all"
            ];
          };

          # plugins = with pkgs.hyprlandPlugins; [
          #   xtra-dispatchers # FIXME: Build Failure
          # ];

          xwayland.enable = true;

          sourceFirst = true;

          settings = {
            monitor = [
              {
                output = "";
                mode = "highres";
                position = "auto";
                transform = 0;
                scale = 1;
              }
              {
                output = "eDP-1";
                mode = "highres";
                position = "auto";
                transform = 0;
                scale = 1;
              }
              {
                output = "HDMI-A-1";
                mode = "highres";
                position = "auto";
                transform = 1; # 1 = 90 Degrees
                scale = 1;
              }
            ];

            on = {
              _args = [
                "hyprland.start"
                (lib.generators.mkLuaInline ''
                  function()
                    hl.exec_cmd("pidof moxnotify || uwsm-app -- moxnotify")
                    hl.exec_cmd("pidof tray-tui || uwsm-app -- xdg-terminal-exec -- tray-tui", {workspace = "special:magic"})
                    hl.exec_cmd("pidof soteria || uwsm-app -- soteria") -- Fallback

                    hl.exec_cmd("uwsm-app -- wl-paste --type text --watch cliphist store")
                    hl.exec_cmd("uwsm-app -- wl-paste --type image --watch cliphist store")
                  end
                '')
              ];
            };

            bind = [
              {
                _args = [
                  "SUPER + L"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"loginctl lock-session\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + L"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- wleave --service=false --show-keybinds=true --no-version-info=true\")")
                ];
              }
              {
                _args = [
                  "SUPER + 1"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 2"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"2\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 3"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"3\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 4"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"4\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 5"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"5\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 6"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"6\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 7"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"7\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 8"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"8\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 9"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"9\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 0"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"10\"})")
                ];
              }
              {
                _args = [
                  "SUPER + mouse_down"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m+1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + mouse_up"
                  (lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m-1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + S"
                  (lib.generators.mkLuaInline " hl.dsp.workspace.toggle_special(\"magic\")")
                ];
              }
              {
                _args = [
                  "SUPER + left"
                  (lib.generators.mkLuaInline "hl.dsp.focus({direction = \"l\"})")
                ];
              }
              {
                _args = [
                  "SUPER + right"
                  (lib.generators.mkLuaInline "hl.dsp.focus({direction = \"r\"})")
                ];
              }
              {
                _args = [
                  "SUPER + up"
                  (lib.generators.mkLuaInline "hl.dsp.focus({direction = \"u\"})")
                ];
              }
              {
                _args = [
                  "SUPER + down"
                  (lib.generators.mkLuaInline "hl.dsp.focus({direction = \"d\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 1"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 2"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"2\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 3"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"3\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 4"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"4\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 5"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"5\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 6"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"6\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 7"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"7\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 8"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"8\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 9"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"9\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 0"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"10\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + S"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"special:magic\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 1"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"1\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 2"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"2\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 3"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"3\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 4"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"4\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 5"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"5\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 6"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"6\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 7"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"7\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 8"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"8\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 9"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"9\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 0"
                  (lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"10\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + F"
                  (lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"fullscreen\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + F"
                  (lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"maximized\"})")
                ];
              }
              {
                _args = [
                  "F11"
                  (lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"fullscreen\"})")
                ];
              }
              {
                _args = [
                  "SUPER + Q"
                  (lib.generators.mkLuaInline "hl.dsp.window.close()")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + Q"
                  (lib.generators.mkLuaInline "hl.dsp.window.kill()")
                ];
              }
              {
                _args = [
                  "Print"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- ferrishot\")")
                ];
              }
              {
                _args = [
                  "SUPER + RETURN"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wofi --show drun --disable-history | xargs -r uwsm-app --\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + RETURN"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wofi --show run --disable-history | xargs -r uwsm-app --\")")
                ];
              }
              {
                _args = [
                  "SUPER + SPACE"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"cliphist list | wofi --dmenu | cliphist decode | wl-copy\")")
                ];
              }
              {
                _args = [
                  "SUPER + T"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec\")")
                ];
              }
              {
                _args = [
                  "XF86Explorer"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- yazi\")")
                ];
              }
              {
                _args = [
                  "SUPER + F"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- yazi\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + B"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- bluetui\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + N"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- wifitui tui\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + ALT + N"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- nmtui\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + A"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- wiremix\")")
                ];
              }
              {
                _args = [
                  "SUPER + Y"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- cal --year\")")
                ];
              }
              {
                _args = [
                  "SUPER + C"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- clock-rs\")")
                ];
              }
              {
                _args = [
                  "SUPER + K"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"keepassxc\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + K"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"keepassxc --lock\")")
                ];
              }
              {
                _args = [
                  "SUPER + U"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- btop\")")
                ];
              }
              {
                _args = [
                  "SUPER + W"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brave\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + W"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brave --incognito\")")
                ];
              }
              {
                _args = [
                  "XF86Mail"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"tutanota-desktop\")")
                ];
              }
              {
                _args = [
                  "SUPER + M"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"tutanota-desktop\")")
                ];
              }
              {
                _args = [
                  "SUPER + E"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- zeditor\")")
                ];
              }
              {
                _args = [
                  "SUPER + D"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"dbgate\")")
                ];
              }
              {
                _args = [
                  "SUPER + O"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- oterm\")")
                ];
              }
              {
                _args = [
                  "XF86MonBrightnessUp"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl s 1%+\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86MonBrightnessDown"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl s 1%-\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioRaiseVolume"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioLowerVolume"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioPlay"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl play-pause\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioPause"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl play-pause\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioStop"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl stop\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioPrev"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl previous\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioNext"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl next\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioMute"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioMicMute"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "SUPER + mouse:272"
                  (lib.generators.mkLuaInline "hl.dsp.window.drag()")
                  {
                    mouse = true;
                  }
                ];
              }
              {
                _args = [
                  "SUPER + mouse:273"
                  (lib.generators.mkLuaInline "hl.dsp.window.resize()")
                  {
                    mouse = true;
                  }
                ];
              }
            ];

            config = {
              binds = {
                disable_keybind_grabbing = true;
                pass_mouse_when_bound = false;

                window_direction_monitor_fallback = true;
              };

              cursor = {
                no_hardware_cursors = false;

                sync_gsettings_theme = true;

                persistent_warps = true;

                no_warps = false;

                hide_on_key_press = false;
                hide_on_touch = true;
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

              dwindle = {
                use_active_for_splits = true;
                force_split = 0; # Follows Mouse
                smart_split = false;
                preserve_split = true;

                smart_resizing = true;
              };

              general = {
                allow_tearing = false;

                gaps_workspaces = 0;

                layout = "dwindle";

                gaps_in = 4;
                gaps_out = {
                  top = 4;
                  right = 4;
                  bottom = 4;
                  left = 4;
                };

                border_size = 1;

                no_focus_fallback = false;

                resize_on_border = true;
                hover_icon_on_border = true;

                snap = {
                  enabled = true;
                  border_overlap = false;
                };
              };

              misc = {
                disable_autoreload = false;

                allow_session_lock_restore = true;

                key_press_enables_dpms = true;
                mouse_move_enables_dpms = true;

                vrr = 1;

                mouse_move_focuses_monitor = true;

                disable_hyprland_logo = true;
                force_default_wallpaper = 1;
                disable_splash_rendering = true;

                font_family = fontPreferences.name.sans_serif;

                close_special_on_empty = true;

                animate_mouse_windowdragging = false;
                animate_manual_resizes = false;

                exit_window_retains_fullscreen = false;

                layers_hog_keyboard_focus = true;

                focus_on_activate = false;

                middle_click_paste = true;
              };

              xwayland = {
                enabled = true;
                force_zero_scaling = true;
                use_nearest_neighbor = true;
              };

              # windowrule = [ ];

              input = {
                kb_layout = "us";

                numlock_by_default = false;

                follow_mouse = 1;
                focus_on_close = 1;

                left_handed = false;
                natural_scroll = false;

                touchpad = {
                  natural_scroll = true;

                  tap_to_click = true;
                  tap_and_drag = true;
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

              gestures = {
                # Touchpad
                workspace_swipe_invert = true;

                # Touchscreen
                workspace_swipe_touch = false;
                workspace_swipe_touch_invert = false;

                workspace_swipe_create_new = true;
                workspace_swipe_forever = true;
              };

              ecosystem = {
                no_update_news = false;
              };
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

          userDirs = {
            createDirectories = true;
            setSessionVariables = true;
          };

          configFile = {
            "mimeapps.list".force = true;

            # "qBittorrent/themes/catppuccin-${config.catppuccin.flavor}.qbtheme" = {
            #   enable = true;
            #   target = "qBittorrent/themes/catppuccin-${config.catppuccin.flavor}.qbtheme";

            #   source = builtins.fetchurl {
            #     url = "https://github.com/catppuccin/qbittorrent/releases/latest/download/catppuccin-${config.catppuccin.flavor}.qbtheme";
            #     sha256 = "1qamhay71jqzi6bq0f8gar55jz2hdwzsfj4d7r14msl1v2ggbpgn";
            #   };

            #   executable = null;
            # };
          };
        };

        gtk = {
          enable = true;

          colorScheme = "dark";
          theme = {
            name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal";
            package = (
              pkgs.catppuccin-gtk.override {
                accents = [
                  config.catppuccin.accent
                ];
                size = "standard";
                tweaks = [
                  "normal"
                ];
                variant = config.catppuccin.flavor;
              }
            );
          };

          font = {
            name = fontPreferences.name.sans_serif;
            package = fontPreferences.package;
            size = fontPreferences.size;
          };

          iconTheme = {
            name = "Papirus-Dark";
            package = (
              pkgs.catppuccin-papirus-folders.override {
                accent = config.catppuccin.accent;
                flavor = config.catppuccin.flavor;
              }
            );
          };

          cursorTheme = {
            name = config.home-manager.users.root.home.pointerCursor.name;
            size = config.home-manager.users.root.home.pointerCursor.size;
          };

          gtk4 = {
            enable = true;

            colorScheme = config.home-manager.users.root.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.root.gtk.theme.name;
              package = config.home-manager.users.root.gtk.theme.package;
            };

            font = {
              name = config.home-manager.users.root.gtk.font.name;
              package = config.home-manager.users.root.gtk.font.package;
              size = config.home-manager.users.root.gtk.font.size;
            };

            iconTheme = {
              name = config.home-manager.users.root.gtk.iconTheme.name;
              package = config.home-manager.users.root.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.root.gtk.cursorTheme.name;
              size = config.home-manager.users.root.gtk.cursorTheme.size;
            };
          };

          gtk3 = {
            enable = true;

            colorScheme = config.home-manager.users.root.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.root.gtk.theme.name;
              package = config.home-manager.users.root.gtk.theme.package;
            };

            font = {
              name = config.home-manager.users.root.gtk.font.name;
              package = config.home-manager.users.root.gtk.font.package;
              size = config.home-manager.users.root.gtk.font.size;
            };

            iconTheme = {
              name = config.home-manager.users.root.gtk.iconTheme.name;
              package = config.home-manager.users.root.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.root.gtk.cursorTheme.name;
              size = config.home-manager.users.root.gtk.cursorTheme.size;
            };
          };

          gtk2 = {
            enable = true;

            theme = {
              name = config.home-manager.users.root.gtk.theme.name;
              package = config.home-manager.users.root.gtk.theme.package;
            };

            font = {
              name = config.home-manager.users.root.gtk.font.name;
              package = config.home-manager.users.root.gtk.font.package;
              size = config.home-manager.users.root.gtk.font.size;
            };

            iconTheme = {
              name = config.home-manager.users.root.gtk.iconTheme.name;
              package = config.home-manager.users.root.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.root.gtk.cursorTheme.name;
              size = config.home-manager.users.root.gtk.cursorTheme.size;
            };
          };
        };

        qt = {
          enable = true;

          platformTheme = {
            name = "qtct";
          };

          style = {
            name = "kvantum";
          };

          qt6ctSettings = {
            Appearance = {
              style = "kvantum-dark";
              color_scheme_path = "${config.catppuccin.sources.qt5ct}/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";
              standard_dialogs = "xdgdesktopportal";
            };
          };

          qt5ctSettings = {
            Appearance = {
              style = config.home-manager.users.root.qt.qt6ctSettings.Appearance.style;
              color_scheme_path = config.home-manager.users.root.qt.qt6ctSettings.Appearance.color_scheme_path;
              standard_dialogs = config.home-manager.users.root.qt.qt6ctSettings.Appearance.standard_dialogs;
            };
          };

          kvantum = {
            enable = true;

            settings = {
              General = {
                theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}";
              };
            };
          };
        };

        services = {
          poweralertd.enable = true;

          udiskie = {
            enable = true;
            package = pkgs.udiskie;

            automount = true;
            tray = "always";
            notify = true;

            settings = {
              terminal = "${config.programs.foot.package}/bin/foot -D";
              file_manager = "${pkgs.xdg-utils}/bin/xdg-open";

              menu = "nested";

              password_cache = 5; # 5 Minutes
            };
          };

          syshud = {
            enable = true;
            package = pkgs.syshud;

            settings = {
              listeners = "keyboard,backlight,audio_in,audio_out";
              position = "bottom";
              orientation = "h";
              show-percentage = true;
              transition-time = 250;
              timeout = 2; # 2 Seconds
            };
          };

          hypridle = {
            enable = true;
            package = pkgs.hypridle;

            settings = {
              general = {
                ignore_systemd_inhibit = false;
                ignore_wayland_inhibit = false;
                ignore_dbus_inhibit = false;

                lock_cmd = "pidof hyprlock || uwsm-app -- hyprlock";
              };

              listener = [
                {
                  ignore_inhibit = false;

                  timeout = 300; # 5 Minutes
                  on-timeout = "loginctl lock-session";
                }
              ];
            };
          };

          wayvnc = {
            enable = config.programs.wayvnc.enable;
            package = config.programs.wayvnc.package;

            settings = {
              address = "127.0.0.1";
              port = 5901;
            };

            autoStart = true;
          };

          hyprpaper = {
            enable = true;
            package = pkgs.hyprpaper;

            settings = {
              ipc = "on";

              splash = false;

              wallpaper = {
                monitor = "";
                recursive = true;
                path = wallpaper;
                fit_mode = "cover";
              };
            };
          };
        };

        programs = {
          # gradle = {
          #   enable = true;
          #   package = pkgs.gradle;
          # }; # flutter adds the compatible version

          matplotlib = {
            enable = true;

            config = {
              axes = {
                grid = true;
              };
            };
          };

          wleave = {
            enable = true;
            package = pkgs.wleave;
          };

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

          bat = {
            enable = config.programs.bat.enable;
            package = config.programs.bat.package;
            extraPackages = config.programs.bat.extraPackages;
          };

          vivid = {
            enable = true;
            package = pkgs.vivid;

            enableBashIntegration = true;

            colorMode = "24-bit";
            activeTheme = "catppuccin-${config.catppuccin.flavor}";
          };

          imv = {
            enable = true;
            package = pkgs.imv;
          };

          lazygit = {
            enable = true;
            package = pkgs.lazygit;

            enableBashIntegration = true;
          };

          onlyoffice = {
            enable = true;
            package = pkgs.onlyoffice-desktopeditors;
          };

          rclone = {
            enable = true;
            package = (
              pkgs.rclone.override {
                enableCmount = true;
              }
            );
          };

          zed-editor = {
            enable = true;
            package = (
              pkgs.zed-editor
              # pkgs.zed-editor.override {
              #   buildRemoteServer = false;
              #   git = config.programs.git.package;
              # }
            );

            installRemoteServer = false;
            enableMcpIntegration = true;

            extensions = [
              "arduino"
              "awk"
              "basher"
              "bloc"
              "bookmark"
              "catppuccin"
              "catppuccin-icons"
              "comment"
              "comment-block-snippets"
              "css-variables"
              "dart"
              "desktop"
              "docker-compose"
              "dockerfile"
              "editorconfig"
              "env"
              "flutter-snippets"
              "github-actions"
              "github-activity-summazier"
              "gitignore-templates"
              "graphql"
              "html-snippets"
              "http"
              "hurl"
              "hyprlang"
              "import-cost-lsp"
              "ini"
              "javascript-snippets"
              "keep-a-changelog-snippets"
              "kubernetes-snippets"
              "latex"
              "live-server"
              "log"
              "logcat"
              "lua"
              "make"
              "markdown-snippets"
              "markdownlinter"
              "mermaid"
              "nix"
              "php"
              "php-snippets"
              "phpcs"
              "phpmd"
              "platformio"
              "postgres-context-server"
              "postgres-language-server"
              "powershell"
              "python-snippets"
              "rainbow-csv"
              "riverpod-dart-flutter-snippets"
              "sql"
              "xml"
            ];

            extraPackages = with pkgs; [
              nixd
              nixfmt
            ];

            mutableUserDebug = true;
            mutableUserKeymaps = true;
            mutableUserSettings = true;
            mutableUserTasks = true;

            userSettings = {
              telemetry = {
                metrics = false;
              };

              terminal = {
                font_family = fontPreferences.name.mono;
                font_size = design_factor;

                cursor_shape = "bar";
                cursor_blink = true;
              };

              vim_mode = false;

              ui_font_family = fontPreferences.name.sans_serif;
              ui_font_size = design_factor;

              buffer_font_family = fontPreferences.name.mono;
              buffer_font_size = design_factor;

              cursor_shape = "bar";
              cursor_blink = true;

              languages = {
                Nix = {
                  language_servers = [
                    "nixd"
                    "!nil"
                  ];

                  formatter = {
                    external = {
                      command = "nixfmt";
                      arguments = [ ];
                    };
                  };
                };
              };

              lsp = {
                nixd = {
                  initialization_options = {
                    formatting = {
                      command = [
                        "nixfmt"
                      ];
                    };
                  };
                };

                dart = {
                  binary = {
                    path = "${pkgs.flutter}/bin/dart";
                    arguments = [
                      "language-server"
                      "--protocol=lsp"
                    ];
                  };
                };
              };

            };

            defaultEditor = true;
          };

          television = {
            enable = true;
            package = pkgs.television;

            enableBashIntegration = true;
          };

          cava = {
            enable = true;
            package = pkgs.cava;
          };

          # texlive = { };

          ssh = {
            enable = true;
            package = config.services.openssh.package;
          };

          jq = {
            enable = true;
            package = (
              pkgs.jq.override {
                onigurumaSupport = true;
              }
            );
          };

          command-not-found.enable = config.programs.command-not-found.enable;

          clock-rs = {
            enable = true;
            package = pkgs.clock-rs;

            settings = {
              general = {
                blink = true;
                bold = true;
              };
            };
          };

          fastfetch = {
            enable = true;
            package = (
              pkgs.fastfetch.override {
                audioSupport = true;
                brightnessSupport = true;
                dbusSupport = true;
                enlightenmentSupport = false;
                flashfetchSupport = false;
                gnomeSupport = false;
                imageSupport = true;
                openclSupport = true;
                openglSupport = true;
                rpmSupport = false;
                sqliteSupport = true;
                terminalSupport = true;
                vulkanSupport = true;
                waylandSupport = true;
                x11Support = false;
                xfceSupport = false;
                zfsSupport = true;
              }
            );
          };

          mangohud = {
            enable = true;
            package = pkgs.mangohud;
          };

          btop = {
            enable = true;
            package = pkgs.btop;
          };

          k9s = {
            enable = true;
            package = pkgs.k9s;
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

          info = {
            enable = true;
            package = pkgs.texinfoInteractive;
          };

          git = {
            enable = true;
            package = config.programs.git.package;

            lfs = {
              enable = true;
              package = config.programs.git.lfs.package;

              skipSmudge = false;
            };
          };

          delta = {
            enable = true;
            package = pkgs.delta;

            enableGitIntegration = true;
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

              editor = "zeditor";
            };
          };

          gh-dash = {
            enable = true;
            package = pkgs.gh-dash;
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

          hyprlock = {
            enable = true;
            package = pkgs.hyprlock;

            sourceFirst = true;

            # settings = {
            #   general = {
            #     immediate_render = true;
            #     fractional_scaling = 2; # 2 = Automatic

            #     text_trim = false;
            #     hide_cursor = false;

            #     ignore_empty_input = true;
            #     fail_timeout = 2000; # ms
            #   };

            #   auth = {
            #     pam = {
            #       enabled = true;
            #       module = "hyprlock";
            #     };

            #     fingerprint = {
            #       enabled = true;

            #       ready_message = "Scan Fingerprint";
            #       present_message = "Scanning Fingerprint";

            #       retry_delay = 250; # ms
            #     };
            #   };

            #   background = [
            #     {
            #       monitor = ""; # "" = All
            #       # path = wallpaper;
            #     }
            #   ];

            #   label = [
            #     {
            #       monitor = ""; # "" = All
            #       halign = "center";
            #       valign = "top";
            #       position = "0, -128";

            #       text_align = "center";
            #       font_family = fontPreferences.name.sans_serif;
            #       # color = convert_hex_color_code_to_rgba_color_code colors.hex.foreground;
            #       font_size = design_factor * 4; # 64
            #       text = "$TIME12";
            #     }

            #     {
            #       monitor = ""; # "" = All
            #       halign = "center";
            #       valign = "center";
            #       position = "0, 0";

            #       text_align = "center";
            #       font_family = fontPreferences.name.sans_serif;
            #       # color = convert_hex_color_code_to_rgba_color_code colors.hex.foreground;
            #       font_size = design_factor;
            #       text = "$DESC"; # Full Name
            #     }
            #   ];

            #   input-field = [
            #     {
            #       monitor = ""; # "" = All
            #       halign = "center";
            #       valign = "bottom";
            #       position = "0, 128";

            #       size = "256, 48";
            #       rounding = design_factor;
            #       outline_thickness = 1;
            #       # outer_color = convert_hex_color_code_to_rgba_color_code colors.hex.background;
            #       shadow_passes = 0;
            #       hide_input = false;
            #       # inner_color = convert_hex_color_code_to_rgba_color_code colors.hex.background;
            #       font_family = fontPreferences.name.sans_serif;
            #       # font_color = convert_hex_color_code_to_rgba_color_code colors.hex.foreground;
            #       placeholder_text = "Enter Password";
            #       dots_center = true;
            #       dots_rounding = -1;

            #       fade_on_empty = true;

            #       invert_numlock = false;
            #       # capslock_color = convert_hex_color_code_to_rgba_color_code colors.hex.warning;
            #       # numlock_color = convert_hex_color_code_to_rgba_color_code colors.hex.warning;
            #       # bothlock_color = convert_hex_color_code_to_rgba_color_code colors.hex.warning;

            #       # check_color = convert_hex_color_code_to_rgba_color_code colors.hex.success;
            #       # fail_color = convert_hex_color_code_to_rgba_color_code colors.hex.error;
            #       fail_text = "$FAIL <b>($ATTEMPTS)</b>";
            #     }
            #   ];
            # };
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
          };

          chromium = {
            enable = true;
            package = (
              pkgs.brave.override {
                enableVideoAcceleration = true;
                enableVulkan = false; # Enabling Breaks Va-API
                libvaSupport = true;
                pulseSupport = false;
                vulkanSupport = false; # Enabling Breaks Va-API
                commandLineArgs = "";
              }
            );

            nativeMessagingHosts = [
              config.home-manager.users.root.programs.keepassxc.package
            ];
          };
          brave.nativeMessagingHosts = config.home-manager.users.root.programs.chromium.nativeMessagingHosts;

          obs-studio = {
            enable = config.programs.obs-studio.enable;
            package = config.programs.obs-studio.package;
            plugins = config.programs.obs-studio.plugins;
          };

          foot = {
            enable = config.programs.foot.enable;
            package = config.programs.foot.package;

            settings = {
              main = {
                term = config.programs.foot.settings.main.term;
                login-shell = config.programs.foot.settings.main.login-shell;

                dpi-aware = config.programs.foot.settings.main.dpi-aware;
                initial-window-mode = config.programs.foot.settings.main.initial-window-mode;
                initial-color-theme = config.programs.foot.settings.main.initial-color-theme;
                pad = config.programs.foot.settings.main.pad;

                font = config.programs.foot.settings.main.font;
                box-drawings-uses-font-glyphs = config.programs.foot.settings.main.box-drawings-uses-font-glyphs;
                horizontal-letter-offset = config.programs.foot.settings.main.horizontal-letter-offset;
                vertical-letter-offset = config.programs.foot.settings.main.vertical-letter-offset;

                selection-target = config.programs.foot.settings.main.selection-target;
              };

              tweak = {
                sixel = config.programs.foot.settings.tweak.sixel;
                surface-bit-depth = config.programs.foot.settings.tweak.surface-bit-depth;
                font-monospace-warn = config.programs.foot.settings.tweak.font-monospace-warn;
              };

              security.osc52 = config.programs.foot.settings.security.osc52;

              url = {
                osc8-underline = config.programs.foot.settings.url.osc8-underline;
              };

              bell = {
                system = config.programs.foot.settings.bell.system;
              };

              scrollback = {
                indicator-position = config.programs.foot.settings.scrollback.indicator-position;
                indicator-format = config.programs.foot.settings.scrollback.indicator-format;
              };

              cursor = {
                style = config.programs.foot.settings.cursor.style;
                unfocused-style = config.programs.foot.settings.cursor.unfocused-style;
                blink = config.programs.foot.settings.cursor.blink;
              };

              mouse = {
                hide-when-typing = config.programs.foot.settings.mouse.hide-when-typing;
              };
            };
          };

          lutris = {
            enable = false; # FIXME: Build Failure
            package = (
              stableNixPackages.lutris-free.override {
                steamSupport = false;
              }
            );

            extraPackages = with pkgs; [
              config.home-manager.users.root.programs.mangohud.package
              gamemode
              gamescope
              protontricks
              winetricks
            ];
            winePackages = with pkgs; [
              wineWow64Packages.waylandFull
            ];
            protonPackages = with pkgs; [
              proton-ge-bin
            ];
          };

          yazi = {
            enable = config.programs.yazi.enable;
            package = config.programs.yazi.package;
            plugins = config.programs.yazi.plugins;

            enableBashIntegration = true;

            settings = config.programs.yazi.settings;
          };

          keychain = {
            enable = true;
            package = pkgs.keychain;

            enableBashIntegration = true;
            enableXsessionIntegration = false;
          };

          wofi = {
            enable = true;
            package = pkgs.wofi;

            settings = {
              normal_window = false;
              layer = "overlay";
              location = "center";

              gtk_dark = true;
              columns = 1;
              dynamic_lines = false;
              height = "75%";
              width = "25%";
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

          nix-index = {
            enable = config.programs.nix-index.enable;
            package = config.programs.nix-index.package;

            enableBashIntegration = config.programs.nix-index.enableBashIntegration;
          };

          man = {
            enable = config.documentation.man.enable;
            package = config.documentation.man.man-db.package;
            man-db.enable = config.documentation.man.man-db.enable;

            generateCaches = config.documentation.man.cache.enable;
          };
        };

        catppuccin = {
          enable = true;

          enableReleaseCheck = true;
          cache.enable = true;

          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;

          cursors = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          bat = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          btop = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          k9s = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;

            transparent = true;
          };

          cava = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;

            transparent = true;
          };

          wleave = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            iconStyle = "wleave";
          };

          brave = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          delta = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          zed = {
            enable = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            icons = {
              enable = true;

              flavor = config.catppuccin.flavor;
            };

            italics = false;
          };

          fcitx5 = {
            enable = config.catppuccin.enable;
            apply = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            enableRounded = true;
          };

          foot = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          television = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          vivid = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          gh-dash = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          gtk.icon.enable = false;

          hyprland = {
            enable = false; # TODO: Later

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          }; # TODO:Check

          hyprlock = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            useDefaultConfig = true;
          };

          hyprtoolkit = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          }; # TODO: Check

          imv = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          kvantum = {
            enable = config.catppuccin.enable;
            assertStyle = true;
            apply = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          lazygit = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          mangohud = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          obs = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          }; # Settings > Appearance > Theme, Style

          qt5ct = {
            enable = config.catppuccin.enable;
            assertPlatformTheme = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          yazi = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };
        };

        manual = {
          manpages.enable = true;
          html.enable = true;
          json.enable = false;
        };
      }
    ];

    users.root = { };
    users.bitscoper = { };

    verbose = true;
  };
}

# FIXME: 05ac-033e-Gamepad > Rumble
# FIXME: ELAN7001 SPI Fingerprint Sensor
