# By Abdullah As-Sadeed

{
  # modulesPath,
  config,
  lib,
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
  catppuccinThemeFlake = builtins.getFlake "github:catppuccin/nix";
  freesmLauncherFlake = builtins.getFlake "github:FreesmTeam/FreesmLauncher";

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
    url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/refs/heads/master/wallpapers/nix-wallpaper-nineish-catppuccin-${config.catppuccin.flavor}.png";
  };

  transparent_1x1_png_file = builtins.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png";
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

        copyKernels = true;

        efiSupport = true;
        zfsSupport = true;
        enableCryptodisk = true;
        useOSProber = true;

        fsIdentifier = "uuid";
        device = "nodev";

        gfxmodeEfi = "1920x1080,auto";
        gfxpayloadEfi = "keep";

        theme = "${pkgs.catppuccin-grub}/"; # From config.nixpkgs.overlays

        splashImage = lib.mkForce wallpaper;
        splashMode = "normal";

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

      timeout = 1; # 1 Second
    };

    kernel = {
      enable = true;

      sysctl = {
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 1;
        "kernel.sysrq" = 1;
        "kernel.unprivileged_bpf_disabled" = 1;

        "net.core.default_qdisc" = "fq";
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_ecn" = 1;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_tw_reuse" = 2; # Loopback Only
        "net.ipv4.tcp_window_scaling" = 1;
      };
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

    extraModulePackages = with config.boot.kernelPackages; [
      apfs
      cpupower
      mm-tools
      openafs
      tmon
      turbostat
      usbip
      v4l2loopback
      zfs_2_4
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
        catppuccin-plymouth # From config.nixpkgs.overlays
      ];
      theme = "catppuccin-${config.catppuccin.flavor}";

      font = "${pkgs.nerd-fonts.noto}/share/fonts/truetype/NerdFonts/Noto/NotoSansNerdFont-Regular.ttf";

      logo = transparent_1x1_png_file; # Due to zero margin between the logo and throbber, and because the shutdown screen does not render the logo like the boot screen.

      # extraConfig = ''
      #   UseFirmwareBackground=true
      # '';
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

    stateVersion = "26.11";
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
        catppuccin-grub =
          (prev.catppuccin-grub.override {
            flavor = config.catppuccin.flavor;
          }).overrideAttrs
            (old: {
              postInstall = (old.postInstall or "") + ''
                cp ${wallpaper} $out/background.png

                rm -f $out/logo.png
                sed -i '/# Logo image/,+5d' $out/theme.txt
                # Because the background already has the NixOS logo.

                # Moving the boot menu to the center of the left half of the screen
                sed -i 's/left = 50%-240/left = 5%/' $out/theme.txt
                sed -i 's/top = 60%/top = 35%/' $out/theme.txt
                sed -i 's/width = 480/width = 40%/' $out/theme.txt

                # Preserving the relative position of the countdown
                sed -i 's/top = 82%/top = 57%/' $out/theme.txt
                sed -i 's/left = 35%/left = 5%/' $out/theme.txt
                sed -i 's/width = 30%/width = 40%/' $out/theme.txt
              ''; # installPhase Runs postInstall
            });
      })

      (final: prev: {
        catppuccin-plymouth =
          (prev.catppuccin-plymouth.override {
            variant = config.catppuccin.flavor;
          }).overrideAttrs
            (old: {
              postInstall = (old.postInstall or "") + ''
                THEME_DIRECTORY=$out/share/plymouth/themes/catppuccin-${config.catppuccin.flavor}

                mkdir -p $THEME_DIRECTORY
                cp ${wallpaper} $THEME_DIRECTORY/background.png
              ''; # installPhase Runs postInstall
            });
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
        openldap = prev.openldap.overrideAttrs {
          doCheck = !prev.stdenv.hostPlatform.isi686;
        };
      }) # Fixes Build Failure of Lutris

      (final: prev: {
        vte = stableNixPackages.vte;
      }) # Fixes Build Failure

      (final: prev: {
        xdg-desktop-portal-hyprland =
          hyprlandFlake.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland.override
            {
              debug = false;
            };
      })
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
        8010 # pkgs.vlc.override { chromecastSupport = true; }
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

    alsa.enable = !config.services.pipewire.alsa.enable;

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
        #     alsaSupport = true;
        #     canokeySupport = false; # Marked as Broken
        #     capstoneSupport = true;
        #     cephSupport = true;
        #     enableBlobs = true;
        #     enableDocs = true;
        #     enableTools = true;
        #     glusterfsSupport = true;
        #     gtkSupport = true;
        #     guestAgentSupport = true;
        #     jackSupport = true;
        #     libiscsiSupport = true;
        #     ncursesSupport = true;
        #     numaSupport = true;
        #     openGLSupport = true;
        #     pipewireSupport = true;
        #     pluginsSupport = true;
        #     pulseSupport = true;
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
      "r /run/current-system/sw/share/wayland-sessions/hyprland.desktop"
      "L+ /etc/xdg/wayland-sessions/hyprland-uwsm.desktop - - - - ${config.programs.hyprland.package}/share/wayland-sessions/hyprland-uwsm.desktop" # From config.nixpkgs.overlays

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
          enablePassim = false;
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

    gvfs = {
      enable = true;
      package = (
        pkgs.gvfs.override {
          gnomeSupport = false;
          udevSupport = true;
        }
      );
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

      packages = [
        config.services.gnome.gcr-ssh-agent.package
        pkgs.libvirt-dbus
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

      sddm = {
        enable = true;
        package = pkgs.qt6Packages.sddm;

        wayland = {
          enable = true;
          compositor = "kwin";
        };

        enableHidpi = true;

        autoNumlock = false;
        autoLogin.relogin = false;

        settings = {
          Wayland.SessionDir = "/etc/xdg/wayland-sessions/"; # With config.systemd.tmpfiles.rules
        };
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

    pulseaudio.enable = !config.services.pipewire.pulse.enable;
    jack = {
      jackd.enable = !config.services.pipewire.jack.enable;
      alsa.enable = !config.services.pipewire.jack.enable;
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
                gnupg
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

    jellyfin = {
      enable = true;
      package = pkgs.jellyfin;

      transcoding.enableSubtitleExtraction = true;

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

      blesh.enable = false; # ble.sh Prevents Cursor from Rendering

      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };

      enableLsColors = true;

      undistractMe.enable = false; # Behaves Strangely

      # shellAliases = { };

      # loginShellInit = '''';
      # shellInit = '''';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';
    };

    starship = {
      enable = true;
      package = pkgs.starship;

      interactiveOnly = true;

      presets = [
        # "catppuccin-powerline"
        "nerd-font-symbols"
      ];

      settings = {
        follow_symlinks = true;

        add_newline = true;

        # palette = "catppuccin_${config.catppuccin.flavor}";
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

    wireshark = {
      enable = true;
      package = (
        pkgs.wireshark.override {
          libpcap = (
            pkgs.libpcap.override {
              withBluez = true;
              withRdma = true;
              withRemote = true;
            }
          );
          withExtras = true;
          withQt = true;
        }
      );

      dumpcap.enable = true;
      usbmon.enable = true;
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

    gnupg = {
      package = (
        pkgs.gnupg1.override {
          gnupg = (
            pkgs.gnupg.override {
              guiSupport = true;
              withPcsc = true;
              withTpm2Tss = true;
            }
          );
        }
      );

      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;
        enableSSHSupport = false;

        pinentryPackage = (
          pkgs.pinentry-curses.override {
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

    nano = {
      enable = true;
      package = (
        pkgs.nano.override {
          enableNls = true;
        }
      );

      syntaxHighlight = true;

      nanorc = ''
        set linenumbers
        set indicator
        set softwrap
        set autoindent
      '';
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
      package = pkgs.hyprland; # From config.nixpkgs.overlays
      portalPackage = pkgs.xdg-desktop-portal-hyprland; # From config.nixpkgs.overlays

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
          alsaSupport = true;
          browserSupport = true;
          pipewireSupport = true;
          pulseaudioSupport = true;
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
      package = pkgs.localsend;

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
        # metadata # FIXME: Build Failure
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
        audacity
        aurea
        autopsy
        avbroot
        avrdude
        banner
        baobab
        bcachefs-tools
        bcg729
        binutils
        binwalk
        bleachbit
        bluez-alsa
        bluez-tools
        brasero
        brightnessctl
        btrfs-assistant
        btrfs-heatmap
        btrfs-progs
        bustle
        butt
        bytecode-viewer
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
        codec2
        codevis
        collision
        colorgrind
        compose2nix
        constrict
        cramfsprogs
        crlfuzz
        cron
        crosspipe
        cryptsetup
        cscope
        ctagsWrapped
        ctop
        cups-pk-helper
        cups-printers
        curtail
        cve-bin-tool
        cyclonedx-cli
        cyclonedx-python
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
        fdupes
        ferrishot
        ffmpegthumbnailer
        ffpb
        fh
        file
        file-roller
        fileinfo
        findutils
        flake-checker
        flare-floss
        flatpak-builder
        flatpak-xdg-utils
        flawz
        flutter
        folder-color-switcher
        font-manager
        fontfor
        fontpreview
        fork-cleaner
        freac
        freecad
        freerouting
        freesmLauncherFlake.packages.${pkgs.stdenv.hostPlatform.system}.default
        fritzing
        fstl
        fwupd-efi
        gama-tui
        gawk
        gcc
        gdb
        genealogos-cli
        gerbolyze
        gimp3-with-plugins
        git-big-picture
        git-filter-repo
        git-repo
        github-changelog-generator
        gitlogue
        gittype
        glib
        globe-cli
        gnome-characters
        gnome-firmware
        gnome-graphs
        gnome-nettool
        gnugrep
        gnumake
        gnused
        gnutar
        google-lighthouse
        gopeed
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
        gucharmap
        guestfs-tools
        gzip
        hashcat
        hashcat-utils
        hashes
        hdparm
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
        hyprmagnifier
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
        imhex
        indent
        inetutils
        inkcut
        inkscape-with-extensions
        inotify-tools
        interactive-html-bom
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
        kubectl
        kubernetes-controller-tools
        kubescape
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
        libqalculate # qalc
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
        md-tui
        meld
        meow
        mermaid-cli
        mesa-demos
        meshlab
        metadata-cleaner
        mfcuk
        mfoc
        minikube
        mmtui
        monkeys-audio
        mousam
        moxnotify
        mslicer
        mt-st
        mtools
        mysqltuner
        nethogs
        nilfs-utils
        ninja
        nix-diff
        nix-info
        nixmate
        nixpkgs-reviewFull
        nmap
        nmgui
        ntfs3g
        numactl
        numatop
        nurl
        nvme-cli
        nwg-clipman
        nwg-drawer
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
        otree
        overskride
        paper-clip
        parallel-full
        parted
        pbzx
        pcb2gcode
        pciutils
        pdfarranger
        pe-bear
        pev
        pg_top
        pgbadger
        pgmodeler
        pgread
        picard
        picard-tools
        pinta
        pipes
        pkg-config
        platformio
        play
        playerctl
        podman-compose
        podman-tui
        poop # POOP = Performance Optimizer Observation Platform
        printrun
        procps
        profile-cleaner
        progress
        protocol
        protonup-qt
        ps
        psmisc
        pwvucontrol
        python3Packages.tkinter
        qalculate-gtk
        qemu-user
        qemu-utils
        qjournalctl
        qr-backup
        qsstv
        qtrvsim
        qtscrcpy
        radare2
        raider
        rar # Unfree
        rclone-browser
        recoll
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
        sbomnix
        schroedinger
        scope-tui
        screen
        sdrangel
        seer # seergdb
        serial-studio
        share-preview
        shellclear
        sherlock
        simple-scan
        sipvicious
        sl
        sleuthkit
        sloc
        smag
        smartmontools
        sof-tools
        songrec
        sound-theme-freedesktop
        soundconverter
        sox
        spectre-meltdown-checker
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
        syft
        symlinks
        systemctl-tui
        szyszka
        telegraph
        termdown
        terminaltexteffects
        termscp
        texliveFull
        texlivePackages.latexmk
        time
        tpm2-tools
        traceroute
        traitor
        tray-tui
        tree
        treegen
        trueseeing
        trufflehog
        trustymail
        tsukae
        ttl
        tutanota-desktop
        udftools
        uefi-firmware-parser
        ugit
        undollar
        unetbootin
        unhide
        unhide-gui
        uni2ascii
        unimatrix
        universal-android-debloater # uad-ng
        unix-privesc-check
        unrar # Unfree
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
        vlc-bittorrent
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
        wayscriber
        weathr
        webcamize
        webfontkitgenerator
        websocat
        wev
        whatfiles
        which
        whois
        whosthere
        windowtolayer
        wl-clipboard
        wordbook
        worldpainter
        wpprobe
        wvkbd # wvkbd-mobintl
        xar
        xdg-dbus-proxy
        xdg-user-dirs
        xdg-utils
        xdot
        xeol
        xfsdump
        xfsprogs
        xhost
        xoscope
        xscreenruler
        xvidcore
        yara-x
        yq
        yuview
        zenity
        zenmap
        zfs
        zip
        zizmor
        (alpaca.override {
          ollama = config.services.ollama.package;
        })
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
        (blender.override {
          jackaudioSupport = true;
          openUsdSupport = true;
          spaceNavSupport = true;
          waylandSupport = true;
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
            withGrayscale = true;
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
        (guvcview.override {
          pulseaudioSupport = true;
          useQt = false;
          useGtk = true;
        })
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
        (nemo-with-extensions.override {
          useDefaultExtensions = true;
          extensions = with pkgs; [
            nemo-emblems
            nemo-fileroller
            nemo-preview
            nemo-python
            nemo-seahorse
          ];
        })
        (nwg-displays.override {
          hyprlandSupport = true;
        })
        (orca-slicer.override {
          withSystemd = true;
        })
        (p7zip.override {
          enableUnfree = true; # Unfree # Includes RAR
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
        (quassel.override {
          client = false; # !monolithic
          enableDaemon = false; # !monolithic
          monolithic = true;
          static = false;
        })
        (qbittorrent.override {
          guiSupport = true;
          trackerSearch = true;
          webuiSupport = true;
        })
        (remmina.override {
          withLibsecret = true;
          withWebkitGtk = true;
          withVte = true;
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
        (tor-browser.override {
          audioSupport = true;
          libnotifySupport = true;
          libvaSupport = true;
          mediaSupport = true;
          pipewireSupport = true;
          pulseaudioSupport = true;
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
        (vlc.override {
          chromecastSupport = true;
          jackSupport = true;
          onlyLibVLC = false;
          skins2Support = true;
          waylandSupport = true;
          withQt5 = true;
        })
        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })
        config.hardware.firmware
        config.home-manager.users.root.programs.dircolors.package
        config.home-manager.users.root.services.udiskie.package
        config.programs.gnupg.agent.pinentryPackage
        config.programs.nix-index.package
        config.services.gnome.gcr-ssh-agent.package
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
          enableAlsa = true;
          enableCdparanoia = true;
          enableDocumentation = true;
          enableWayland = true;
        })
        (gst-plugins-good.override {
          enableDocumentation = true;
          enableJack = true;
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
          "kitty.desktop"
        ];
      };
    };

    portal = {
      enable = true;
      extraPortals = [
        config.programs.hyprland.portalPackage
        pkgs.xdg-desktop-portal-gtk
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
        "inode/directory" = "nemo.desktop";

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
        "audio/soundfont" = "vlc.desktop";
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
        "audio/vnd.blockfact.facta" = "vlc.desktop";
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
        "audio/vnd.qcelp" = "vlc.desktop";
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
        "video/jpeg2000-scl" = "vlc.desktop";
        "video/jpeg2000" = "vlc.desktop";
        "video/jxsv" = "vlc.desktop";
        "video/lottie+json" = "vlc.desktop";
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
        "video/vnd.blockfact.factv" = "vlc.desktop";
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
        "video/vnd.planar" = "vlc.desktop";
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

        "application/pdf" = "sioyek.desktop";

        "model/stl" = "fstlapp-fstl.desktop";

        "application/gzip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-arj" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gtar" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed " = "org.gnome.FileRoller.desktop"; # More common than "application/vnd.rar"
        "application/x-tar" = "org.gnome.FileRoller.desktop";
        "application/zip" = "org.gnome.FileRoller.desktop";

        "font/collection" = "com.github.FontManager.FontViewer.desktop";
        "font/otf" = "com.github.FontManager.FontViewer.desktop";
        "font/sfnt" = "com.github.FontManager.FontViewer.desktop";
        "font/ttf" = "com.github.FontManager.FontViewer.desktop";
        "font/woff" = "com.github.FontManager.FontViewer.desktop";
        "font/woff2" = "com.github.FontManager.FontViewer.desktop";

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
        "jellyfin"
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
        "wireshark"
      ];

      useDefaultShell = true;
    };
  };

  catppuccin = {
    enable = true;

    enableReleaseCheck = true;
    cache.enable = true;

    autoEnable = true;
    flavor = "mocha";
    accent = "lavender";

    grub.enable = false; # Done Manually

    tty = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
    };

    plymouth.enable = false; # Done Manually

    sddm = {
      enable = true;
      assertQt6Sddm = true;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;

      background = wallpaper;

      font = fontPreferences.name.sans_serif;
      fontSize = toString fontPreferences.size;

      loginBackground = true;
      userIcon = true;

      clockEnabled = true;
    };

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

            permitJellyfin = ''
              ${pkgs.acl}/bin/setfacl --modify user:jellyfin:--x $HOME
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

          configType = "lua";
          sourceFirst = true;

          extraConfig = ''
            require("monitors")
          ''; # nwg-displays

          settings = {
            monitor = [
              {
                output = ""; # "" = All
                mode = "highres";
                position = "auto";
                transform = 0;
                scale = 1;
              } # Default
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
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-drawer -ovl -closebtn none -c 8 -g ${config.home-manager.users.root.gtk.theme.name} -i ${config.home-manager.users.root.gtk.iconTheme.name} -pbuseicontheme -lang en -k -wm uwsm -term kitty -fm nemo\")") # TODO: Use uwsm-app
                ];
              }
              {
                _args = [
                  "SUPER + ALT + RETURN"
                  (lib.generators.mkLuaInline ''
                    hl.dsp.exec_cmd("uwsm-app -- xdg-terminal-exec -- --hold sh -c 'exec sh -c \"$(compgen -c | sort -u | tv)\"'")
                  '')
                ];
              }
              {
                _args = [
                  "SUPER + SPACE"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-clipman --numbers\")")
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
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nemo\")")
                ];
              }
              {
                _args = [
                  "SUPER + F"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nemo\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + B"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- overskride\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + D"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-displays\")")
                ];
              }
              {
                _args = [
                  "SUPER + CTRL + N"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nmgui\")")
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
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- pwvucontrol\")")
                ];
              }
              {
                _args = [
                  "SUPER + Y"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- xdg-terminal-exec -- --hold cal --year\")")
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
                  "SUPER + A"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wayscriber --no-tray --active\")")
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

            "qBittorrent/themes/catppuccin-${config.catppuccin.flavor}.qbtheme" = {
              enable = true;

              source = builtins.fetchurl {
                url = "https://github.com/catppuccin/qbittorrent/releases/latest/download/catppuccin-${config.catppuccin.flavor}.qbtheme";
              };

              target = "qBittorrent/themes/catppuccin-${config.catppuccin.flavor}.qbtheme";
              executable = null;
            };
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
              terminal = "${config.xdg.terminal-exec.package}/bin/xdg-terminal-exec -- --working-directory";
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
              pkgs.zed-editor.override {
                buildRemoteServer = true;
              }
            );

            extraPackages =
              with pkgs;
              [
                arduino-language-server
                basedpyright
                bash-language-server
                css-variables-language-server
                ctags-lsp
                docker-compose-language-service
                dockerfile-language-server
                hyprls
                kotlin-language-server
                nixd
                nixfmt
                postgres-language-server
                prettier
                ruff
                shellcheck
                shfmt
                sql-formatter
                yaml-language-server
              ]
              ++ [
                config.home-manager.users.root.programs.opencode.package
                config.home-manager.users.root.programs.sioyek.package
              ];

            installRemoteServer = true;
            enableMcpIntegration = true;

            # curl -s https://raw.githubusercontent.com/zed-industries/extensions/main/.gitmodules
            extensions = [
              "arduino"
              "assembly"
              "awk"
              "basher"
              "bloc"
              "bookmark"
              "catppuccin"
              "catppuccin-icons"
              "comment"
              "comment-block-snippets"
              "css-variables"
              "csv"
              "ctags"
              "dart"
              "desktop"
              "docker-compose"
              "dockerfile"
              "editorconfig"
              "emoji-completions"
              "env"
              "flutter-snippets"
              "github-actions"
              "github-activity-summarizer"
              "gitignore-templates"
              "graphql"
              "graphviz"
              "groovy"
              "html-snippets"
              "http"
              "hurl"
              "hyprlang"
              "import-cost-lsp"
              "ini"
              "intl-lens"
              "javascript-snippets"
              "keep-a-changelog-snippets"
              "kubernetes-snippets"
              "latex"
              "live-server"
              "log"
              "logcat"
              "ltex"
              "lua"
              "make"
              "markdown-snippets"
              "markdownlint"
              "mermaid"
              "nix"
              "opencode"
              "pbxproj"
              "php"
              "php-snippets"
              "phpcs"
              "phpmd"
              "platformio"
              "postgres-context-server"
              "postgres-language-server"
              "powershell"
              "python-requirements"
              "python-snippets"
              "regedit"
              "riverpod-dart-flutter-snippets"
              "rpmspec"
              "sieve"
              "sql"
              "ssh-config"
              "stylelint"
              "toml"
              "unicode"
              "vcard"
              "xml"
            ];

            mutableUserDebug = true;
            mutableUserKeymaps = true;
            mutableUserSettings = true;
            mutableUserTasks = true;

            userSettings = {
              telemetry = {
                diagnostics = false;
                metrics = false;
              };

              title_bar = {
                show_branch_name = true;
                show_branch_status_icon = true;
                show_menus = true;
                show_onboarding_banner = true;
                show_project_items = true;
                show_sign_in = true;
                show_user_menu = true;
                show_user_picture = true;
              };

              toolbar = {
                agent_review = true;
                breadcrumbs = true;
                code_actions = true;
                quick_actions = true;
                selections_menu = true;
              };

              status_bar = {
                active_language_button = true;
                cursor_position_button = true;
                line_endings_button = true;
              };

              project_panel = {
                button = true;

                sticky_scroll = true;
                entry_spacing = "comfortable";

                indent_guides = {
                  show = "always";
                };

                hide_root = false;
                hide_hidden = false;
                sort_mode = "directories_first";

                folder_icons = true;
                file_icons = true;
                git_status = true;
                show_diagnostics = "all";

                scrollbar = {
                  show = "auto";
                };

                drag_and_drop = true;
              };

              file_finder = {
                file_icons = true;
              };

              outline_panel = {
                button = true;

                folder_icons = true;
                file_icons = true;
                git_status = true;

                indent_guides = {
                  show = "always";
                };

                scrollbar = {
                  show = "auto";
                };
              };

              git_panel = {
                button = true;

                scrollbar = {
                  show = "auto";
                };
              };

              collaboration_panel = {
                button = true;
              };

              terminal = {
                button = true;

                toolbar = {
                  breadcrumbs = true;
                };

                scrollbar = {
                  show = "auto";
                };

                font_family = fontPreferences.name.mono;
                font_size = design_factor;
                line_height = "comfortable";

                cursor_shape = "bar";
                blinking = "on";

                copy_on_select = false;
                keep_selection_on_copy = true;

                detect_venv = {
                  on = {
                    directories = [
                      ".venv"
                      "venv"
                    ];
                    activate_script = "default";
                  };
                };
              };

              debugger = {
                button = true;
              };

              tab_bar = {
                show = true;

                show_tab_bar_buttons = true;
                show_nav_history_buttons = true;
              };

              tabs = {
                file_icons = true;

                show_close_button = "hover";
                close_position = "right";

                git_status = true;
                show_diagnostics = "all";
              };

              search = {
                button = true;
              };

              gutter = {
                line_numbers = true;
                runnables = true;
                breakpoints = true;
                folds = true;
              };

              scrollbar = {
                show = "auto";
                axes = {
                  horizontal = true;
                  vertical = true;
                };

                cursors = true;
                diagnostics = "all";
                git_diff = true;
                search_results = true;
                selected_symbol = true;
                selected_text = true;
              };

              minimap = {
                show = "auto";
                display_in = "all_editors";
                thumb = "always";
              };

              sticky_scroll = {
                enabled = true;
              };

              indent_guides = {
                enabled = true;

                coloring = "indent_aware";
                background_coloring = "disabled";
              };

              git = {
                inline_blame = {
                  enabled = true;

                  show_commit_summary = true;
                };

                hunk_style = "staged_hollow";
              };

              diagnostics = {
                button = true;

                inline = {
                  enabled = true;
                };
              };

              inlay_hints = {
                enabled = true;

                show_background = false;

                show_type_hints = true;
                show_parameter_hints = true;
                show_other_hints = true;
              };

              edit_predictions = {
                mode = "subtle";

                provider = "ollama";
                ollama = { };
              };

              agent = {
                enabled = true;
                button = true;

                # default_model = {
                #   provider = "ollama";
                # };

                # inline_alternatives = [
                #   {
                #     provider = "ollama";
                #   }
                # ];
              };

              use_system_prompts = true;
              use_system_path_prompts = true;

              vim_mode = false;
              hide_mouse = "never";

              show_call_status_icon = true;

              ui_font_family = fontPreferences.name.sans_serif;
              ui_font_size = design_factor;

              buffer_font_family = fontPreferences.name.mono;
              buffer_font_size = design_factor;
              buffer_font_features = {
                calt = false; # Ligatures
              };

              cursor_shape = "bar";
              cursor_blink = true;

              soft_wrap = "editor_width";
              show_whitespaces = "all";
              show_wrap_guides = true;
              lsp_document_colors = "inlay";
              colorize_brackets = true;
              current_line_highlight = "all";
              inline_code_actions = true;

              show_completions_on_input = true;
              show_completion_documentation = true;
              completion_menu_scrollbar = "auto";
              auto_signature_help = true;
              show_signature_help_after_edits = true;

              format_on_save = "on";
              hard_tabs = false;
              tab_size = 2;

              redact_private_values = true;

              file_types = {
                Diff = [
                  "diff"
                ];

                Dockerfile = [
                  "Dockerfile.*"
                ];

                "GitHub Actions" = [
                  ".github/workflows/*.yaml"
                  ".github/workflows/*.yml"
                ];

                "Python constraints" = [
                  "*constraints*.txt"
                ];
                "Python requirements" = [
                  "**/requirements/*.{in,txt}"
                  "*requirements*.{in,txt}"
                ];
              };

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

                "Shell Script" = {
                  formatter = {
                    external = {
                      command = "shfmt";
                      arguments = [
                        "--filename"
                        "{buffer_path}"
                        "--indent"
                        "2"
                      ];
                    };
                  };
                };

                C = {
                  language_servers = [
                    "ctags-lsp"
                  ];
                };

                "C++" = {
                  language_servers = [
                    "ctags-lsp"
                  ];
                };

                PHP = {
                  language_servers = [
                    "phpactor"
                    "phpcs"
                    "phpmd"
                    "ctags-lsp"
                    "!intelephense"
                    "!phptools"
                  ];

                  code_actions_on_format = {
                    "source.fixAll" = true;
                  };
                };

                JavaScript = {
                  formatter = {
                    external = {
                      command = "prettier";
                      arguments = [
                        "--stdin-filepath"
                        "{buffer_path}"
                      ];
                    };
                  };

                  code_actions_on_format = {
                    "source.fixAll.eslint" = true;
                  };
                };

                Python = {
                  language_servers = [
                    "basedpyright"
                    "ruff"
                    "ctags-lsp"
                  ];

                  formatter = {
                    language_server = {
                      name = "ruff";
                    };
                  };

                  code_actions_on_format = {
                    "source.organizeImports.ruff" = true;
                  };
                };

                SQL = {
                  formatter = {
                    external = {
                      command = "sql-formatter";
                      # arguments = [
                      #   "--language"
                      #   "postgresql"
                      # ];
                      # arguments = [
                      #   "--language"
                      #   "mariadb"
                      # ];
                    };
                  };
                };

                CSS = {
                  code_actions_on_format = {
                    "source.fixAll.stylelint" = true;
                  };
                };

                Markdown = {
                  indent_list_on_tab = true;
                  extend_list_on_newline = true;

                  remove_trailing_whitespace_on_save = false;
                };
              };

              global_lsp_settings = {
                button = true;

                semantic_token_rules = [
                  {
                    token_type = "comment";
                  }
                ];
              };

              lsp = {
                # unicode = {
                #   settings = {
                #     include_all_symbols = true;
                #   };
                # };

                nixd = {
                  initialization_options = {
                    formatting = {
                      command = [
                        "nixfmt"
                      ];
                    };
                  };
                };

                clangd = {
                  binary = {
                    path = "${pkgs.clang-tools}/bin/clangd";
                    arguments = [ ];
                  };
                };

                arduino-language-server = {
                  binary = {
                    path = "${pkgs.arduino-language-server}/bin/arduino-language-server";
                    arguments = [
                      "--fqbn"
                      "arduino:avr"
                    ];
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

                phpmd = {
                  settings = {
                    rulesets = "cleancode,codesize,controversial,design,naming,unusedcode";
                  };
                };

                eslint = {
                  settings = {
                    workingDirectory = {
                      mode = "auto";
                    };
                  };
                };

                css-variables = {
                  settings = {
                    cssVariables = {
                      undefinedVarFallback = "info";
                    };
                  };
                };

                ltex = {
                  settings = {
                    ltex = {
                      language = "auto";
                    };
                  };
                };
                texlab = {
                  settings = {
                    texlab = {
                      build = {
                        onSave = true;
                        forwardSearchAfter = true;
                      };
                      forwardSearch = {
                        executable = "sioyek";
                        args = [
                          "--reuse-window"
                          "--execute-command"
                          "toggle_synctex"
                          "--inverse-search"
                          "texlab inverse-search -i \"%%1\" -l %%2"
                          "--forward-search-file"
                          "%f"
                          "--forward-search-line"
                          "%l"
                          "%p"
                        ];
                      };
                    };
                  };
                };

                yaml-language-server = {
                  binary = {
                    path = "${pkgs.yaml-language-server}/bin/yaml-language-server";
                    arguments = [ ];
                  };

                  settings = {
                    yaml = {
                      schemaStore = {
                        enable = true;
                      };

                      keyOrdering = true;
                      singleQuote = false;
                    };
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

          mcp = {
            enable = true;
          };

          opencode = {
            enable = true;
            package = pkgs.opencode;

            enableMcpIntegration = true;

            web = {
              enable = false;
            };
          };

          sioyek = {
            enable = true;
            package = pkgs.sioyek;

            # config.startup_commands = [
            #   "toggle_dark_mode"
            # ];
          };

          cava = {
            enable = true;
            package = pkgs.cava;
          };

          kitty = {
            enable = true;
            package = pkgs.kitty;

            shellIntegration = {
              enableBashIntegration = true;
            };

            enableGitIntegration = true;

            font = {
              name = fontPreferences.name.mono;
              package = pkgs.nerd-fonts.noto;
              size = fontPreferences.size;
            };

            extraConfig = {
              enable_audio_bell = true;
              sync_to_monitor = "no";
            };

            # environment = { };
          };

          bash = {
            enable = true;

            enableVteIntegration = config.programs.bash.vteIntegration;
            enableCompletion = config.programs.bash.completion.enable;

            shellAliases = config.programs.bash.shellAliases;
          };

          starship = {
            enable = config.programs.starship.enable;
            package = config.programs.starship.package;

            # extraPackages = with pkgs; [ ];

            enableBashIntegration = true;

            enableInteractive = config.programs.starship.interactiveOnly;

            presets = config.programs.starship.presets;
            settings = config.programs.starship.settings;
          };

          # texlive = { };

          ssh = {
            enable = true;
            package = config.services.openssh.package;

            enableDefaultConfig = false;
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
              gh-skyline # Generates STL File
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

            settings = {
              general = {
                immediate_render = true;
                fractional_scaling = 2; # 2 = Automatic

                text_trim = false;
                hide_cursor = false;

                ignore_empty_input = true;
              };

              auth = {
                pam = {
                  enabled = true;
                  module = "hyprlock";
                };

                fingerprint = {
                  enabled = true;
                };
              };

              background = [
                {
                  monitor = ""; # "" = All
                  path = wallpaper;
                }
              ];
            }; # Addition
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
                pulseSupport = true;
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

          lutris = {
            enable = true;
            package = (
              pkgs.lutris.override {
                steamSupport = false;
              }
            );

            extraPackages =
              with pkgs;
              [
                gamemode
                gamescope
                protontricks
                winetricks
              ]
              ++ [
                config.home-manager.users.root.programs.mangohud.package
              ];
            winePackages = with pkgs; [
              wineWow64Packages.waylandFull
            ];
            protonPackages = with pkgs; [
              proton-ge-bin
            ];
          };

          keychain = {
            enable = true;
            package = pkgs.keychain;

            enableBashIntegration = true;
            enableXsessionIntegration = false;
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
          enable = config.catppuccin.enable;

          enableReleaseCheck = config.catppuccin.enableReleaseCheck;
          cache.enable = config.catppuccin.cache.enable;

          autoEnable = config.catppuccin.autoEnable;
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

          kitty = {
            enable = true;

            flavor = config.catppuccin.flavor;
          };

          opencode = {
            enable = true;

            flavor = config.catppuccin.flavor;
          };

          sioyek = {
            enable = true;

            flavor = config.catppuccin.flavor;
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
          };

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
