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
  cromiteFlake = builtins.getFlake "github:Impqxr/cromite-nix-flake/main";
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

      trusted-users = [
        "root"
        "@wheel"
      ];

      substituters = [
        "https://hyprland.cachix.org/"
      ];

      require-sigs = true;
      trusted-substituters = config.nix.settings.substituters;
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
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

      permittedInsecurePackages = [
        "opendkim-2.11.0-Beta2"
        "ventoy-gtk3-1.1.12"
      ];

      android_sdk.accept_license = config.nixpkgs.config.allowUnfree;
    };

    overlays = [
      (final: previous: {
        catppuccin-grub =
          (previous.catppuccin-grub.override {
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

      (final: previous: {
        catppuccin-plymouth =
          (previous.catppuccin-plymouth.override {
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

      (final: previous: {
        cromite = cromiteFlake.packages.${pkgs.stdenv.hostPlatform.system}.default;
      }) # Addition

      (final: previous: {
        hyprland = (
          hyprlandFlake.packages.${pkgs.stdenv.hostPlatform.system}.hyprland.override {
            debug = false;
            enableXWayland = true;
            withSystemd = true;
            wrapRuntimeDeps = true;
          }
        );
      })

      (final: previous: {
        openldap = previous.openldap.overrideAttrs {
          doCheck = !previous.stdenv.hostPlatform.isi686;
        };
      }) # Fixes Build Failure of Lutris

      (final: previous: {
        pipewire = previous.pipewire.override {
          bluezSupport = true;
          enableSystemd = true;
          raopSupport = true;
          rocSupport = true;
          vulkanSupport = true;
          zeroconfSupport = true;
        };
      })

      (final: previous: {
        psono = final.appimageTools.wrapType2 {
          pname = "psono";
          version = "latest";

          src = final.fetchurl {
            url = "https://get.psono.com/psono/psono-app/latest/psono-linux-x64.AppImage";
            hash = "sha256-YJnEG4OgdX4gTniG8XYPaJs4le0VelPlz47pXdx+0r0=";
          };

          extraPkgs =
            pkgs: with pkgs; [
              libepoxy
              libsoup_3
              webkitgtk_4_1
            ];
        };
      }) # Addition # FIXME: .desktop

      (final: previous: {
        raindropio = final.appimageTools.wrapType2 {
          pname = "raindropio";
          version = "latest";

          src = final.fetchurl {
            url = "https://github.com/raindropio/desktop/releases/latest/download/Raindrop-arm64.AppImage";
            hash = "sha256-ixg+SN8bWXtBnK3dPGGrTwS2ujvB/HkqakXjQ4wuav8=";
          };

          # extraPkgs = pkgs: with pkgs; [ ];
        };
      }) # Addition # FIXME: .desktop # FIXME: Exec Format Error

      (final: previous: {
        seabird = stableNixPackages.seabird;
      }) # Fixes Building Forever

      (final: previous: {
        vte = stableNixPackages.vte;
      }) # Fixes Build Failure

      (final: previous: {
        xdg-desktop-portal-hyprland =
          hyprlandFlake.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland.override
            {
              debug = false;
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
        "net.ipv4.tcp_tw_reuse" = 2; # 2 = Loopback Only
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

  hardware = {
    enableAllFirmware = config.nixpkgs.config.allowUnfree;
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

          ResumeDelay = 2; # 2 Seconds
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

  zramSwap = {
    enable = true;
    algorithm = config.boot.tmp.zramSettings.compression-algorithm;
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

    useDHCP = false; # Managed by NetworkManager Instead
    dhcpcd.enable = false;

    modemmanager = {
      enable = true;
      package = (
        pkgs.modemmanager.override {
          withIntrospection = true;
          withPolkit = true;
          withSystemd = true;
        }
      );
    };

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
        config.home-manager.users.normal.services.wayvnc.settings.port
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

  time = {
    timeZone = "Asia/Dhaka";
    hardwareClockInLocalTime = false;
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
      # extraPackages = with pkgs; [ ];
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

  services = {
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

    timesyncd = {
      enable = false; # FIXME: Disabled due to Misbehavior

      servers = config.networking.timeServers;
      fallbackServers = config.networking.timeServers;
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

      extraRules = ''
        SUBSYSTEM=="backlight", ACTION=="add", KERNEL=="*", MODE="0666" RUN+="${config.home-manager.users.normal.programs.dircolors.package}/bin/chmod a+w /sys/class/backlight/%k/brightness"
      ''; # config.home-manager.users.normal.programs.dircolors.package = Overriden coreutils-full
    };

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

    zram-generator = {
      enable = true;
      package = pkgs.zram-generator;
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

    accounts-daemon.enable = true;

    fprintd = {
      enable = true;
      package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;

      # tod = {
      #   enable = true;
      #   driver = ;
      # };
    };

    pipewire = {
      enable = true;
      package = pkgs.pipewire; # From config.nixpkgs.overlays

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
        ServerAdmin root@${config.networking.fqdn}
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
    };

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
        user = "root";
        password = config.secrets.password_1;
      };

      extraConfig = ''
        <location>${config.networking.fqdn}</location>
        <admin>root@${config.networking.fqdn}</admin>
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

    kubernetes = {
      package = pkgs.kubernetes;
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

    logrotate = {
      enable = true;

      allowNetworking = true;
      checkConfig = true;
    };
  };

  programs = {
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
      package = pkgs.hyprland; # From config.nixpkgs.overlays
      portalPackage = pkgs.xdg-desktop-portal-hyprland; # From config.nixpkgs.overlays

      withUWSM = true;
      xwayland.enable = true;
    };

    xwayland.enable = true;

    gamemode = {
      enable = true;
      enableRenice = true;
    };

    bash = {
      vteIntegration = true;

      completion = {
        enable = true;
        package = pkgs.bash-completion;
      };

      blesh.enable = true; # FIXME: Enabling Prevents Cursor from Rendering

      enableLsColors = true;

      undistractMe.enable = false; # FIXME: Disabled due to Misbehavior

      # shellAliases = { };

      # loginShellInit = '''';

      # shellInit = '''';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';

      # promptInit = '''';

      # logout = '''';
    };

    fish = {
      enable = true;
      package = (
        pkgs.fish.override {
          useOperatingSystemEtc = true;
          usePython = true;
        }
      );

      vendor = {
        config.enable = true;
        functions.enable = true;
        completions.enable = true;
      };

      generateCompletions = true;
      # extraCompletionPackages = with pkgs; [ ];

      useBabelfish = false; # Errors if Enabled # Disabling Uses foreign-env

      # shellAbbrs = { };

      # shellAliases = { };

      # loginShellInit = '''';

      # shellInit = '''';

      interactiveShellInit = ''
        set -g fish_greeting
      '';

      # promptInit = '''';
    };

    starship = {
      enable = true;
      package = pkgs.starship;

      interactiveOnly = true;

      presets = [
        "nerd-font-symbols"
      ];

      settings = {
        follow_symlinks = true;

        add_newline = true;
      };
    };

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

    nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
      enableFishIntegration = true;
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

    appimage = {
      enable = true;
      package = (
        pkgs.appimage-run.override {
          extraPkgs =
            pkgs: with pkgs; [
              libepoxy
              libsoup_3
              webkitgtk_4_1
            ];
        }
      );

      binfmt = true;
    };

    command-not-found.enable = true;

    direnv = {
      enable = true;
      package = pkgs.direnv;

      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };

      loadInNixShell = true;

      enableBashIntegration = true;
      enableFishIntegration = true;

      silent = false;
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

    usbtop.enable = true;

    television = {
      enable = true;
      package = pkgs.television;

      enableBashIntegration = true;
      enableFishIntegration = true;
    };

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
        # core # FIXME: Build Failure
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
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
          pkgs.pinentry-gtk2.override {
            withLibsecret = true;
          }
        );
      };

      dirmngr.enable = true;
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
          name = config.users.users.normal.description;
          email = "bitscoper@tutanota.com";
        };
      };
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

    waybar = {
      enable = false; # Started by Home Manager Instead
      package = (
        pkgs.waybar.override {
          cavaSupport = true;
          enableManpages = true;
          evdevSupport = true;
          experimentalPatches = true;
          gpsSupport = true;
          inputSupport = true;
          jackSupport = true;
          mpdSupport = false;
          mprisSupport = true;
          niriSupport = false;
          nlSupport = true;
          pipewireSupport = true;
          pulseSupport = true;
          rfkillSupport = true;
          sndioSupport = true;
          systemdSupport = true;
          traySupport = true;
          udevSupport = true;
          upowerSupport = true;
          wireplumberSupport = true;
          withMediaPlayer = true;

          runTests = false;
        }
      );
    };

    nm-applet = {
      enable = false;
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

    firefox = {
      enable = true;
      package = pkgs.firefox-devedition;

      languagePacks = [
        "en-US"
      ];

      policies = {
        SkipTermsOfUse = true;

        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisableFirefoxAccounts = true;
        DisablePocket = true;

        AppAutoUpdate = false;
        BackgroundAppUpdate = false;
        NoDefaultBookmarks = true;

        HardwareAcceleration = true;
        PostQuantumKeyAgreementEnabled = true;
        DisablePrivateBrowsing = false;
        CaptivePortal = true;

        DisableDeveloperTools = false;
        AllowFileSelectionDialogs = true;
        DisableBuiltinPDFViewer = false;
        VisualSearchEnabled = true;
        SearchSuggestEnabled = true;
        TranslateEnabled = true;
        PrintingEnabled = true;

        HttpsOnlyMode = "force_enabled";
        OfferToSaveLogins = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        PromptForDownloadLocation = false;
        StartDownloadsInTempDirectory = false;

        ExtensionSettings =
          let
            linkFormat = linkPart: "https://addons.mozilla.org/firefox/downloads/latest/${linkPart}/latest.xpi";
          in
          {
            "@testpilot-containers" = {
              install_url = linkFormat "multi-account-containers";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "FirefoxColor@mozilla.com" = {
              install_url = linkFormat "firefox-color";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "uBlock0@raymondhill.net" = {
              install_url = linkFormat "ublock-origin";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "jid1-BoFifL9Vbdl2zQ@jetpack" = {
              install_url = linkFormat "decentraleyes";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "sponsorBlocker@ajay.app" = {
              install_url = linkFormat "sponsorblock";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{dcb8caa2-63fa-41aa-a508-a45c5990ebdd}" = {
              install_url = linkFormat "zjm-whatfont";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" = {
              install_url = linkFormat "search_by_image";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{531906d3-e22f-4a6c-a102-8057b88a1a63}" = {
              install_url = linkFormat "single-file";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{c5d69a8f-2ed0-46a7-afa4-b3a00dc58088}" = {
              install_url = linkFormat "gopeed-extension";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "languagetool-webextension@languagetool.org" = {
              install_url = linkFormat "languagetool";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{3dce78ca-2a07-4017-9111-998d4f826625}" = {
              install_url = linkFormat "psono-pw-password-manager";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "jid0-adyhmvsP91nUO8pRv0Mn2VKeB84@jetpack" = {
              install_url = linkFormat "raindropio";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "vpn@proton.ch" = {
              install_url = linkFormat "proton-vpn-firefox-extension";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{8446b178-c865-4f5c-8ccc-1d7887811ae3}" = {
              install_url = linkFormat "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-git";
              installation_mode = "normal_installed";
              updates_disabled = false;
            }; # Hardcoded ID for Catppuccin Mocha Lavender
          };
      };
    };

    evince = {
      enable = true;
      package = (
        pkgs.evince.override {
          supportMultimedia = true;
          withLibsecret = true;
        }
      );
    };

    ghidra = {
      enable = true;
      package = pkgs.ghidra;
      gdb = true;
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

    wayvnc = {
      enable = true;
      package = pkgs.wayvnc;
    };

    localsend = {
      enable = true;
      package = pkgs.localsend;

      openFirewall = true;
    };

    ssh = {
      package = config.services.openssh.package;

      startAgent = false; # `services.gnome.gcr-ssh-agent.enable' and `programs.ssh.startAgent' cannot both be enabled at the same time.
      agentTimeout = null;
    };
  };

  fonts = {
    enableDefaultPackages = false;
    packages =
      with pkgs;
      [
        nerd-fonts.noto
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        noto-fonts-lgc-plus
      ]
      ++ lib.optionals config.nixpkgs.config.allowUnfree [
        corefonts
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
      config.home-manager.users.normal.programs.bash.package
      config.programs.fish.package
    ];

    enableAllTerminfo = true;

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    systemPackages =
      with pkgs;
      [
        # binwalk # FIXME: Build Failure
        # dart # flutter adds the compatible version
        # parallel-full # FIXME: Build Failure
        # reiser4progs # Marked as Broken
        # uefi-firmware-parser # FIXME: Build Failure
        # xfstests # FIXME: Build Failure
        aalib
        aapt
        acl
        acpica-tools
        acpidump-all
        act
        actionlint
        addlicense
        aeskeyfind
        aircrack-ng
        alac
        alsa-plugins
        alsa-tools
        alsa-utils
        alsa-utils-nhlt
        android-backup-extractor
        ansilove
        apfsprogs
        apkeep
        apkleaks
        app-icon-preview
        appimageupdate-qt
        arduino-cli
        ascii
        ascii-draw
        ascii-image-converter
        asciinema
        asciinema-agg
        asciiquarium-transparent
        asnmap
        atac
        audacity
        aurea
        autopsy
        avbroot
        avrdude
        bada-bib
        baobab
        bcachefs-tools
        bcg729
        binary
        binutils
        blanket
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
        cartero
        cavasik
        cbonsai
        cdrkit
        celeste
        celestia
        celt
        censor
        certbot-full
        certdump
        cicero-tui
        clang-analyzer
        clang-tools
        clang_22
        clapgrep
        clapper
        clapper-enhancers
        clinfo
        cloc
        cmake
        cobang
        codec2
        codevis
        colorgrind
        compose2nix
        concessio
        constrict
        contrast
        coulomb
        cozy
        cramfsprogs
        crlfuzz
        cron
        cryptsetup
        cscope
        ctagsWrapped
        ctop
        cups-pk-helper
        cups-printers
        cursor-clip
        curtail
        cve-bin-tool
        cyclonedx-cli
        cyclonedx-python
        d-spy
        daemon
        darktable
        dbeaver-bin # Disabling Theming Allows to Use GTK Theme
        dconf-editor
        dconf2nix
        ddrescue
        ddrescueview
        debase
        delineate
        dialect
        diffoci
        dig
        dippi
        dive
        dmg2img
        dmidecode
        dnsrecon
        door-knocker
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
        elastic
        elf-dissector
        eloquent
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
        field-monitor
        file
        file-roller
        fileinfo
        findutils
        firefox_decrypt
        flake-checker
        flare-floss
        flatpak-builder
        flatpak-xdg-utils
        flawz
        flutter
        folder-color-switcher
        foliate
        font-manager
        fontfor
        fontforge-gtk
        fork-cleaner
        freac
        freecad
        freerouting
        fritzing
        fstl
        fwupd-efi
        gama-tui
        gamepad-mirror
        gawk
        gcc
        gdb
        gearlever
        genealogos-cli
        gerbolyze
        gimp3-with-plugins
        git-big-picture
        git-filter-repo
        git-repo
        github-changelog-generator
        gitlogue
        glib
        globe-cli
        gnome-characters
        gnome-firmware
        gnome-frog
        gnome-graphs
        gnome-multi-writer
        gnome-nettool
        gnome-podcasts
        gnome-tecla
        gnss-share
        gnugrep
        gnumake
        gnused
        gnutar
        go2tv
        google-lighthouse
        gopeed
        gource
        gpg-tui
        gpredict
        gpu-viewer
        gradle-completion
        graphviz
        greaseweazle
        groovy
        gsm
        gsmartcontrol
        gthumb
        gtk-frdp
        gtk-vnc
        gtkhash
        gucharmap
        guestfs-tools
        gzip
        halftone
        hashcat
        hashcat-utils
        hashes
        hdparm
        helvum
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
        hyprmagnifier
        hyprpicker
        hyprshutdown
        hyprtoolkit
        hyprutils
        hyprwayland-scanner
        hyprwire
        i2c-tools
        iaito
        iconic
        iftop
        ifuse
        imhex
        impression
        indent
        inetutils
        inkcut
        inkscape-with-extensions
        inotify-tools
        interactive-html-bom
        interception-tools
        iotop-c
        iplookup-gtk
        jfsutils
        jmol
        jstest-gtk
        jxrlib
        karere
        karlender
        kdePackages.kmahjongg
        kernel-hardening-checker
        kernelshark
        kexec-tools
        killall
        kind
        kmod
        kotlin
        krapslog
        kubectl
        kubernetes-controller-tools
        kubescape
        kubeshark
        learn6502
        lenspect
        letterpress
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
        libultrahdr
        libva-utils
        libvpx
        linux-exploit-suggester
        linux-wifi-hotspot
        linuxConsoleTools
        livecaptions
        lld_22
        llmfit
        llvm_22
        lock
        logtop
        lorem
        lsb-release
        lshw
        lsof
        lsscsi
        lssecret
        luminance
        lvm2
        lynis
        lyrebird
        lyto
        lyx
        lzham
        macchanger
        mailcap
        mapscii
        md-tui
        mdns-scanner
        meld
        mermaid-cli
        mesa-demos
        meshlab
        metadata
        metadata-cleaner
        metronome
        mfcuk
        mfoc
        millisecond
        minikube
        modem-manager-gui
        monkeys-audio
        morphosis
        mousam
        mslicer
        mt-st
        mtools
        mysqltuner
        nethogs
        netpeek
        networkmanagerapplet # Provides nm-connection-editor
        newelle
        newsflash
        nilfs-utils
        ninja
        nix-diff
        nix-forecast
        nix-health
        nix-info
        nix-query-tree-viewer
        nixmate
        nixpkgs-reviewFull
        nmap
        nmgui
        noaa-apt
        nocturne
        ntfs3g
        nucleus
        numactl
        numatop
        nurl
        nvme-cli
        nwg-bar
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
        orbvis
        otree
        overskride
        paleta
        pana
        paper-clip
        parallel # Instead of parallel-full
        parted
        pbzx
        pcb2gcode
        pciutils
        pdfarranger
        pe-bear
        pev
        pg_top
        pgbadger
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
        pods
        poop # POOP = Performance Optimizer Observation Platform
        powershell
        printrun
        procps
        profile-cleaner
        progress
        protocol
        proton-vpn
        protonplus
        protonup-qt
        ps
        psmisc
        psono # From config.nixpkgs.overlays
        pwvucontrol
        python3Packages.tkinter
        qalculate-gtk
        qemu-user
        qemu-utils
        qr-backup
        qsstv
        qtrvsim
        qtscrcpy
        quick-lookup
        radare2
        raider
        raindropio # From config.nixpkgs.overlays
        resources
        rp-pppoe
        rpi-imager
        rpmextract
        rtl-sdr-librtlsdr
        rubyPackages.cocoapods
        runme
        rustc
        satdump
        satellite
        sbc
        sbom2dot
        sbomnix
        schroedinger
        scorecard
        screen
        sdrangel
        seabird
        seer # seergdb
        semver-tool
        share-preview
        shellclear
        sherlock
        shortwave
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
        sourcegit
        sox
        spectre-meltdown-checker
        speedtest
        spytrap-adb
        srain
        sslscan
        steam-run-free
        stellarium
        stenc
        stockpile
        streamlit
        subfinder
        subtitleeditor
        svt-av1
        switcheroo
        syft
        symbolic-preview
        symlinks
        systemctl-tui
        szyszka
        tauno-monitor
        telegraph
        teleprompter
        termdown
        terminaltexteffects
        texliveFull
        texlivePackages.latexmk
        time
        tpm2-tools
        traceroute
        traitor
        tree
        treegen
        trueseeing
        trufflehog
        trustymail
        tsukae
        ttl
        turnon
        tutanota-desktop
        udftools
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
        valuta
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
        wayland-protocols
        wayland-scanner
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
        wike
        wildcard
        windowtolayer
        wl-clipboard
        wpprobe
        wvkbd # wvkbd-mobintl
        xar
        xdg-dbus-proxy
        xdg-user-dirs
        xdg-user-dirs-gtk
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
            withUnfree = config.nixpkgs.config.allowUnfree;
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

        (gparted-full.override {
          withAllTools = true;
        })

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
          # addons = with pkgs.kicadAddons; [
          #   kikit
          #   kikit-library
          # ]; # FIXME: Build Failure
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
          enableUnfree = config.nixpkgs.config.allowUnfree; # Includes RAR
        })

        (parabolic.override {
          yt-dlp = config.home-manager.users.normal.programs.yt-dlp.package;
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

        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })

        config.hardware.firmware
        config.home-manager.users.normal.programs.dircolors.package # Overriden coreutils-full
        config.home-manager.users.normal.programs.tirith.package
        config.home-manager.users.normal.services.udiskie.package
        config.programs.gnupg.agent.pinentryPackage
        config.programs.nix-index.package
        config.services.gnome.gcr-ssh-agent.package
        config.services.phpfpm.phpPackage
      ]

      ++ lib.optionals config.nixpkgs.config.allowUnfree [
        androidComposition.androidsdk # Custom Composition
        anydesk
        rar
        unrar
      ]

      ++ config.boot.extraModulePackages
      ++ config.fonts.packages
      ++ config.hardware.graphics.extraPackages
      ++ config.hardware.graphics.extraPackages32
      ++ config.hardware.sane.extraBackends
      ++ config.home-manager.users.normal.programs.gh.extensions
      ++ config.home-manager.users.normal.programs.lutris.extraPackages
      ++ config.home-manager.users.normal.programs.lutris.winePackages
      ++ config.home-manager.users.normal.programs.zed-editor.extraPackages
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
        # ghidraninja-ghidra-scripts # FIXME: Build Failure
        findcrypt
        ghidra-delinker-extension
        ghidra-golanganalyzerextension
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

      ++ (with kdePackages; [
        kcachegrind
        kjournald # kjournaldbrowser
        kmahjongg
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
        tree-sitter-fish
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
          "${pkgs.rockyou}/share/wordlists/rockyou.txt"
          # (builtins.toFile "extra-wordlist" '''')
        ];
      };
    };

    variables = {
      LD_LIBRARY_PATH = lib.mkForce "${
        pkgs.lib.makeLibraryPath (
          with pkgs;
          [
            sqlite
          ]
        )
      }:$LD_LIBRARY_PATH";

      GI_TYPELIB_PATH = lib.mkForce "${pkgs.libportal}/lib/girepository-1.0:${pkgs.libportal-gtk4}/lib/girepository-1.0:GI_TYPELIB_PATH";
    }
    // lib.optionalAttrs config.nixpkgs.config.allowUnfree {
      ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk/ndk-bundle";
    };

    sessionVariables = {
      ADW_DISABLE_PORTAL = 1;

      NIXOS_OZONE_WL = 1;
      MOZ_ENABLE_WAYLAND = 1;

      CHROME_EXECUTABLE = "cromite";

      XCURSOR_THEME = config.home-manager.users.normal.home.pointerCursor.name;
      XCURSOR_SIZE = config.home-manager.users.normal.home.pointerCursor.size;
    };

    shellAliases = {
      unbind_i8042_driver = "echo -n i8042 | sudo tee /sys/bus/platform/drivers/i8042/unbind >/dev/null";
      bind_i8042_driver = "echo -n i8042 | sudo tee /sys/bus/platform/drivers/i8042/bind >/dev/null";

      commands = "uwsm-app -- xdg-terminal-exec bash -c 'bash -ic \"$(compgen -c | sort -u | tv)\"; exec fish'";

      clean_upgrade = "sudo nh clean all && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
      clean_repair_upgrade = "sudo nh clean all && sudo nix-store --verify --check-contents --repair && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
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
          "org.gnome.Ptyxis.desktop"
        ];
      };
    };

    portal = {
      enable = true;
      extraPortals =
        with pkgs;
        [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-luminous
        ]
        ++ [
          config.programs.hyprland.portalPackage
        ];

      xdgOpenUsePortal = false;

      config = {
        common = {
          default = [
            "gtk"
          ];

          "org.freedesktop.impl.portal.Secret" = [
            "gnome-keyring"
          ];
        };

        hyprland = {
          default = [
            "luminous"
            "hyprland"
            "gtk"
          ];

          "org.freedesktop.impl.portal.FileChooser" = [
            "gtk"
          ];
          "org.freedesktop.impl.portal.OpenURI" = [
            "gtk"
          ];

          "org.freedesktop.impl.portal.ScreenShot" = [
            "luminous"
          ];
          "org.freedesktop.impl.portal.ScreenCast" = [
            "luminous"
          ];
          "org.freedesktop.impl.portal.InputCapture" = [
            "luminous"
          ];
          "org.freedesktop.impl.portal.RemoteDesktop" = [
            "luminous"
          ];
          "org.freedesktop.impl.portal.Settings" = [
            "luminous"
          ];

          "org.freedesktop.impl.portal.GlobalShortcuts" = [
            "hyprland"
          ];
        };
      }; # FIXME: Does Not Work
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

        "image/aces" = "org.gnome.gThumb.desktop";
        "image/apng" = "org.gnome.gThumb.desktop";
        "image/avci" = "org.gnome.gThumb.desktop";
        "image/avcs" = "org.gnome.gThumb.desktop";
        "image/avif" = "org.gnome.gThumb.desktop";
        "image/bmp" = "org.gnome.gThumb.desktop";
        "image/cgm" = "org.gnome.gThumb.desktop";
        "image/dicom-rle" = "org.gnome.gThumb.desktop";
        "image/dpx" = "org.gnome.gThumb.desktop";
        "image/emf" = "org.gnome.gThumb.desktop";
        "image/fits" = "org.gnome.gThumb.desktop";
        "image/g3fax" = "org.gnome.gThumb.desktop";
        "image/gif" = "org.gnome.gThumb.desktop";
        "image/heic-sequence" = "org.gnome.gThumb.desktop";
        "image/heic" = "org.gnome.gThumb.desktop";
        "image/heif-sequence" = "org.gnome.gThumb.desktop";
        "image/heif" = "org.gnome.gThumb.desktop";
        "image/hej2k" = "org.gnome.gThumb.desktop";
        "image/hsj2" = "org.gnome.gThumb.desktop";
        "image/ief" = "org.gnome.gThumb.desktop";
        "image/j2c" = "org.gnome.gThumb.desktop";
        "image/jaii" = "org.gnome.gThumb.desktop";
        "image/jais" = "org.gnome.gThumb.desktop";
        "image/jls" = "org.gnome.gThumb.desktop";
        "image/jp2" = "org.gnome.gThumb.desktop";
        "image/jpeg" = "org.gnome.gThumb.desktop";
        "image/jph" = "org.gnome.gThumb.desktop";
        "image/jphc" = "org.gnome.gThumb.desktop";
        "image/jpm" = "org.gnome.gThumb.desktop";
        "image/jpx" = "org.gnome.gThumb.desktop";
        "image/jxl" = "org.gnome.gThumb.desktop";
        "image/jxr" = "org.gnome.gThumb.desktop";
        "image/jxrA" = "org.gnome.gThumb.desktop";
        "image/jxrS" = "org.gnome.gThumb.desktop";
        "image/jxs" = "org.gnome.gThumb.desktop";
        "image/jxsc" = "org.gnome.gThumb.desktop";
        "image/jxsi" = "org.gnome.gThumb.desktop";
        "image/jxss" = "org.gnome.gThumb.desktop";
        "image/ktx" = "org.gnome.gThumb.desktop";
        "image/ktx2" = "org.gnome.gThumb.desktop";
        "image/naplps" = "org.gnome.gThumb.desktop";
        "image/png" = "org.gnome.gThumb.desktop";
        "image/prs.btif" = "org.gnome.gThumb.desktop";
        "image/prs.pti" = "org.gnome.gThumb.desktop";
        "image/pwg-raster" = "org.gnome.gThumb.desktop";
        "image/svg+xml" = "org.gnome.gThumb.desktop";
        "image/t38" = "org.gnome.gThumb.desktop";
        "image/tiff-fx" = "org.gnome.gThumb.desktop";
        "image/tiff" = "org.gnome.gThumb.desktop";
        "image/vnd.adobe.photoshop" = "org.gnome.gThumb.desktop";
        "image/vnd.airzip.accelerator.azv" = "org.gnome.gThumb.desktop";
        "image/vnd.blockfact.facti" = "org.gnome.gThumb.desktop";
        "image/vnd.clip" = "org.gnome.gThumb.desktop";
        "image/vnd.cns.inf2" = "org.gnome.gThumb.desktop";
        "image/vnd.dece.graphic" = "org.gnome.gThumb.desktop";
        "image/vnd.djvu" = "org.gnome.gThumb.desktop";
        "image/vnd.dvb.subtitle" = "org.gnome.gThumb.desktop";
        "image/vnd.dwg" = "org.gnome.gThumb.desktop";
        "image/vnd.dxf" = "org.gnome.gThumb.desktop";
        "image/vnd.fastbidsheet" = "org.gnome.gThumb.desktop";
        "image/vnd.fpx" = "org.gnome.gThumb.desktop";
        "image/vnd.fst" = "org.gnome.gThumb.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "org.gnome.gThumb.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "org.gnome.gThumb.desktop";
        "image/vnd.globalgraphics.pgb" = "org.gnome.gThumb.desktop";
        "image/vnd.microsoft.icon" = "org.gnome.gThumb.desktop";
        "image/vnd.mix" = "org.gnome.gThumb.desktop";
        "image/vnd.mozilla.apng" = "org.gnome.gThumb.desktop";
        "image/vnd.ms-modi" = "org.gnome.gThumb.desktop";
        "image/vnd.net-fpx" = "org.gnome.gThumb.desktop";
        "image/vnd.pco.b16" = "org.gnome.gThumb.desktop";
        "image/vnd.radiance" = "org.gnome.gThumb.desktop";
        "image/vnd.sealed.png" = "org.gnome.gThumb.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "org.gnome.gThumb.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "org.gnome.gThumb.desktop";
        "image/vnd.svf" = "org.gnome.gThumb.desktop";
        "image/vnd.tencent.tap" = "org.gnome.gThumb.desktop";
        "image/vnd.valve.source.texture" = "org.gnome.gThumb.desktop";
        "image/vnd.wap.wbmp" = "org.gnome.gThumb.desktop";
        "image/vnd.xiff" = "org.gnome.gThumb.desktop";
        "image/vnd.zbrush.pcx" = "org.gnome.gThumb.desktop";
        "image/webp" = "org.gnome.gThumb.desktop";
        "image/wmf" = "org.gnome.gThumb.desktop";
        "image/x-emf" = "org.gnome.gThumb.desktop";
        "image/x-wmf" = "org.gnome.gThumb.desktop";

        "audio/1d-interleaved-parityfec" = "com.jeffser.Nocturne.desktop";
        "audio/32kadpcm" = "com.jeffser.Nocturne.desktop";
        "audio/3gpp" = "com.jeffser.Nocturne.desktop";
        "audio/3gpp2" = "com.jeffser.Nocturne.desktop";
        "audio/aac" = "com.jeffser.Nocturne.desktop";
        "audio/ac3" = "com.jeffser.Nocturne.desktop";
        "audio/AMR-WB" = "com.jeffser.Nocturne.desktop";
        "audio/amr-wb+" = "com.jeffser.Nocturne.desktop";
        "audio/AMR" = "com.jeffser.Nocturne.desktop";
        "audio/aptx" = "com.jeffser.Nocturne.desktop";
        "audio/asc" = "com.jeffser.Nocturne.desktop";
        "audio/ATRAC-ADVANCED-LOSSLESS" = "com.jeffser.Nocturne.desktop";
        "audio/ATRAC-X" = "com.jeffser.Nocturne.desktop";
        "audio/ATRAC3" = "com.jeffser.Nocturne.desktop";
        "audio/basic" = "com.jeffser.Nocturne.desktop";
        "audio/BV16" = "com.jeffser.Nocturne.desktop";
        "audio/BV32" = "com.jeffser.Nocturne.desktop";
        "audio/clearmode" = "com.jeffser.Nocturne.desktop";
        "audio/CN" = "com.jeffser.Nocturne.desktop";
        "audio/DAT12" = "com.jeffser.Nocturne.desktop";
        "audio/dls" = "com.jeffser.Nocturne.desktop";
        "audio/dsr-es201108" = "com.jeffser.Nocturne.desktop";
        "audio/dsr-es202050" = "com.jeffser.Nocturne.desktop";
        "audio/dsr-es202211" = "com.jeffser.Nocturne.desktop";
        "audio/dsr-es202212" = "com.jeffser.Nocturne.desktop";
        "audio/DV" = "com.jeffser.Nocturne.desktop";
        "audio/DVI4" = "com.jeffser.Nocturne.desktop";
        "audio/eac3" = "com.jeffser.Nocturne.desktop";
        "audio/encaprtp" = "com.jeffser.Nocturne.desktop";
        "audio/EVRC-QCP" = "com.jeffser.Nocturne.desktop";
        "audio/EVRC" = "com.jeffser.Nocturne.desktop";
        "audio/EVRC0" = "com.jeffser.Nocturne.desktop";
        "audio/EVRC1" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCB" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCB0" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCB1" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCNW" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCNW0" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCNW1" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCWB" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCWB0" = "com.jeffser.Nocturne.desktop";
        "audio/EVRCWB1" = "com.jeffser.Nocturne.desktop";
        "audio/EVS" = "com.jeffser.Nocturne.desktop";
        "audio/flac" = "com.jeffser.Nocturne.desktop";
        "audio/flexfec" = "com.jeffser.Nocturne.desktop";
        "audio/fwdred" = "com.jeffser.Nocturne.desktop";
        "audio/G711-0" = "com.jeffser.Nocturne.desktop";
        "audio/G719" = "com.jeffser.Nocturne.desktop";
        "audio/G722" = "com.jeffser.Nocturne.desktop";
        "audio/G7221" = "com.jeffser.Nocturne.desktop";
        "audio/G723" = "com.jeffser.Nocturne.desktop";
        "audio/G726-16" = "com.jeffser.Nocturne.desktop";
        "audio/G726-24" = "com.jeffser.Nocturne.desktop";
        "audio/G726-32" = "com.jeffser.Nocturne.desktop";
        "audio/G726-40" = "com.jeffser.Nocturne.desktop";
        "audio/G728" = "com.jeffser.Nocturne.desktop";
        "audio/G729" = "com.jeffser.Nocturne.desktop";
        "audio/G7291" = "com.jeffser.Nocturne.desktop";
        "audio/G729D" = "com.jeffser.Nocturne.desktop";
        "audio/G729E" = "com.jeffser.Nocturne.desktop";
        "audio/GSM-EFR" = "com.jeffser.Nocturne.desktop";
        "audio/GSM-HR-08" = "com.jeffser.Nocturne.desktop";
        "audio/GSM" = "com.jeffser.Nocturne.desktop";
        "audio/iLBC" = "com.jeffser.Nocturne.desktop";
        "audio/ip-mr_v2.5" = "com.jeffser.Nocturne.desktop";
        "audio/L16" = "com.jeffser.Nocturne.desktop";
        "audio/L20" = "com.jeffser.Nocturne.desktop";
        "audio/L24" = "com.jeffser.Nocturne.desktop";
        "audio/L8" = "com.jeffser.Nocturne.desktop";
        "audio/LPC" = "com.jeffser.Nocturne.desktop";
        "audio/matroska" = "com.jeffser.Nocturne.desktop";
        "audio/MELP" = "com.jeffser.Nocturne.desktop";
        "audio/MELP1200" = "com.jeffser.Nocturne.desktop";
        "audio/MELP2400" = "com.jeffser.Nocturne.desktop";
        "audio/MELP600" = "com.jeffser.Nocturne.desktop";
        "audio/mhas" = "com.jeffser.Nocturne.desktop";
        "audio/midi-clip" = "com.jeffser.Nocturne.desktop";
        "audio/mobile-xmf" = "com.jeffser.Nocturne.desktop";
        "audio/mp4" = "com.jeffser.Nocturne.desktop";
        "audio/MP4A-LATM" = "com.jeffser.Nocturne.desktop";
        "audio/mpa-robust" = "com.jeffser.Nocturne.desktop";
        "audio/MPA" = "com.jeffser.Nocturne.desktop";
        "audio/mpeg" = "com.jeffser.Nocturne.desktop";
        "audio/mpeg4-generic" = "com.jeffser.Nocturne.desktop";
        "audio/ogg" = "com.jeffser.Nocturne.desktop";
        "audio/opus" = "com.jeffser.Nocturne.desktop";
        "audio/parityfec" = "com.jeffser.Nocturne.desktop";
        "audio/PCMA-WB" = "com.jeffser.Nocturne.desktop";
        "audio/PCMA" = "com.jeffser.Nocturne.desktop";
        "audio/PCMU-WB" = "com.jeffser.Nocturne.desktop";
        "audio/PCMU" = "com.jeffser.Nocturne.desktop";
        "audio/prs.sid" = "com.jeffser.Nocturne.desktop";
        "audio/QCELP" = "com.jeffser.Nocturne.desktop";
        "audio/raptorfec" = "com.jeffser.Nocturne.desktop";
        "audio/RED" = "com.jeffser.Nocturne.desktop";
        "audio/rtp-enc-aescm128" = "com.jeffser.Nocturne.desktop";
        "audio/rtp-midi" = "com.jeffser.Nocturne.desktop";
        "audio/rtploopback" = "com.jeffser.Nocturne.desktop";
        "audio/rtx" = "com.jeffser.Nocturne.desktop";
        "audio/scip" = "com.jeffser.Nocturne.desktop";
        "audio/SMV-QCP" = "com.jeffser.Nocturne.desktop";
        "audio/SMV" = "com.jeffser.Nocturne.desktop";
        "audio/SMV0" = "com.jeffser.Nocturne.desktop";
        "audio/sofa" = "com.jeffser.Nocturne.desktop";
        "audio/soundfont" = "com.jeffser.Nocturne.desktop";
        "audio/sp-midi" = "com.jeffser.Nocturne.desktop";
        "audio/speex" = "com.jeffser.Nocturne.desktop";
        "audio/t140c" = "com.jeffser.Nocturne.desktop";
        "audio/t38" = "com.jeffser.Nocturne.desktop";
        "audio/telephone-event" = "com.jeffser.Nocturne.desktop";
        "audio/TETRA_ACELP_BB" = "com.jeffser.Nocturne.desktop";
        "audio/TETRA_ACELP" = "com.jeffser.Nocturne.desktop";
        "audio/tone" = "com.jeffser.Nocturne.desktop";
        "audio/TSVCIS" = "com.jeffser.Nocturne.desktop";
        "audio/UEMCLIP" = "com.jeffser.Nocturne.desktop";
        "audio/ulpfec" = "com.jeffser.Nocturne.desktop";
        "audio/usac" = "com.jeffser.Nocturne.desktop";
        "audio/VDVI" = "com.jeffser.Nocturne.desktop";
        "audio/VMR-WB" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.3gpp.iufp" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.4SB" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.audiokoz" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.blockfact.facta" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.CELP" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.cisco.nse" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.cmles.radio-events" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.cns.anp1" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.cns.inf1" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dece.audio" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.digital-winds" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dlna.adts" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.heaac.1" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.heaac.2" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.mlp" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.mps" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.pl2" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.pl2x" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.pl2z" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dolby.pulse.1" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dra" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dts.hd" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dts.uhd" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dts" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.dvb.file" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.everad.plj" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.hns.audio" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.lucent.voice" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.ms-playready.media.pya" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.nokia.mobile-xmf" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.nortel.vbk" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.nuera.ecelp4800" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.nuera.ecelp7470" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.nuera.ecelp9600" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.octel.sbc" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.presonus.multitrack" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.qcelp" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.rhetorex.32kadpcm" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.rip" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.sealedmedia.softseal.mpeg" = "com.jeffser.Nocturne.desktop";
        "audio/vnd.vmx.cvsd" = "com.jeffser.Nocturne.desktop";
        "audio/vorbis-config" = "com.jeffser.Nocturne.desktop";
        "audio/vorbis" = "com.jeffser.Nocturne.desktop";

        "video/1d-interleaved-parityfec" = "com.github.rafostar.Clapper.desktop";
        "video/3gpp-tt" = "com.github.rafostar.Clapper.desktop";
        "video/3gpp" = "com.github.rafostar.Clapper.desktop";
        "video/3gpp2" = "com.github.rafostar.Clapper.desktop";
        "video/AV1" = "com.github.rafostar.Clapper.desktop";
        "video/BMPEG" = "com.github.rafostar.Clapper.desktop";
        "video/BT656" = "com.github.rafostar.Clapper.desktop";
        "video/CelB" = "com.github.rafostar.Clapper.desktop";
        "video/DV" = "com.github.rafostar.Clapper.desktop";
        "video/encaprtp" = "com.github.rafostar.Clapper.desktop";
        "video/evc" = "com.github.rafostar.Clapper.desktop";
        "video/FFV1" = "com.github.rafostar.Clapper.desktop";
        "video/flexfec" = "com.github.rafostar.Clapper.desktop";
        "video/H261" = "com.github.rafostar.Clapper.desktop";
        "video/H263-1998" = "com.github.rafostar.Clapper.desktop";
        "video/H263-2000" = "com.github.rafostar.Clapper.desktop";
        "video/H263" = "com.github.rafostar.Clapper.desktop";
        "video/H264-RCDO" = "com.github.rafostar.Clapper.desktop";
        "video/H264-SVC" = "com.github.rafostar.Clapper.desktop";
        "video/H264" = "com.github.rafostar.Clapper.desktop";
        "video/H265" = "com.github.rafostar.Clapper.desktop";
        "video/H266" = "com.github.rafostar.Clapper.desktop";
        "video/iso.segment" = "com.github.rafostar.Clapper.desktop";
        "video/JPEG" = "com.github.rafostar.Clapper.desktop";
        "video/jpeg2000-scl" = "com.github.rafostar.Clapper.desktop";
        "video/jpeg2000" = "com.github.rafostar.Clapper.desktop";
        "video/jxsv" = "com.github.rafostar.Clapper.desktop";
        "video/lottie+json" = "com.github.rafostar.Clapper.desktop";
        "video/matroska-3d" = "com.github.rafostar.Clapper.desktop";
        "video/matroska" = "com.github.rafostar.Clapper.desktop";
        "video/mj2" = "com.github.rafostar.Clapper.desktop";
        "video/MP1S" = "com.github.rafostar.Clapper.desktop";
        "video/MP2P" = "com.github.rafostar.Clapper.desktop";
        "video/MP2T" = "com.github.rafostar.Clapper.desktop";
        "video/mp4" = "com.github.rafostar.Clapper.desktop";
        "video/MP4V-ES" = "com.github.rafostar.Clapper.desktop";
        "video/mpeg" = "com.github.rafostar.Clapper.desktop";
        "video/mpeg4-generic" = "com.github.rafostar.Clapper.desktop";
        "video/MPV" = "com.github.rafostar.Clapper.desktop";
        "video/nv" = "com.github.rafostar.Clapper.desktop";
        "video/ogg" = "com.github.rafostar.Clapper.desktop";
        "video/parityfec" = "com.github.rafostar.Clapper.desktop";
        "video/pointer" = "com.github.rafostar.Clapper.desktop";
        "video/quicktime" = "com.github.rafostar.Clapper.desktop";
        "video/raptorfec" = "com.github.rafostar.Clapper.desktop";
        "video/raw" = "com.github.rafostar.Clapper.desktop";
        "video/rtp-enc-aescm128" = "com.github.rafostar.Clapper.desktop";
        "video/rtploopback" = "com.github.rafostar.Clapper.desktop";
        "video/rtx" = "com.github.rafostar.Clapper.desktop";
        "video/scip" = "com.github.rafostar.Clapper.desktop";
        "video/smpte291" = "com.github.rafostar.Clapper.desktop";
        "video/SMPTE292M" = "com.github.rafostar.Clapper.desktop";
        "video/ulpfec" = "com.github.rafostar.Clapper.desktop";
        "video/vc1" = "com.github.rafostar.Clapper.desktop";
        "video/vc2" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.blockfact.factv" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.CCTV" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dece.hd" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dece.mobile" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dece.mp4" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dece.pd" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dece.sd" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dece.video" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.directv.mpeg-tts" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.directv.mpeg" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dlna.mpeg-tts" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.dvb.file" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.fvt" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.hns.video" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.iptvforum.1dparityfec-1010" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.iptvforum.1dparityfec-2005" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.iptvforum.2dparityfec-1010" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.iptvforum.2dparityfec-2005" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.iptvforum.ttsavc" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.iptvforum.ttsmpeg2" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.motorola.video" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.motorola.videop" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.mpegurl" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.ms-playready.media.pyv" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.nokia.interleaved-multimedia" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.nokia.mp4vr" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.nokia.videovoip" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.objectvideo" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.planar" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.radgamettools.bink" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.radgamettools.smacker" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.sealed.mpeg1" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.sealed.mpeg4" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.sealed.swf" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.sealedmedia.softseal.mov" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.uvvu.mp4" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.vivo" = "com.github.rafostar.Clapper.desktop";
        "video/vnd.youtube.yt" = "com.github.rafostar.Clapper.desktop";
        "video/VP8" = "com.github.rafostar.Clapper.desktop";
        "video/VP9" = "com.github.rafostar.Clapper.desktop";
        "video/x-matroska" = "com.github.rafostar.Clapper.desktop"; # https://mime.wcode.net/mkv

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

        "application/pdf" = "org.gnome.Evince.desktop";

        "model/stl" = "fstlapp-fstl.desktop";

        "application/gzip" = "org.gnome.FileRoller.desktop";
        "application/vnd.rar" = "org.gnome.FileRoller.desktop";
        "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
        "application/x-arj" = "org.gnome.FileRoller.desktop";
        "application/x-bzip2" = "org.gnome.FileRoller.desktop";
        "application/x-gtar" = "org.gnome.FileRoller.desktop";
        "application/x-rar-compressed " = "org.gnome.FileRoller.desktop"; # More Common Than "application/vnd.rar"
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

        "x-scheme-handler/http" = "firefox-devedition.desktop";
        "x-scheme-handler/https" = "firefox-devedition.desktop";

        "x-scheme-handler/mailto" = "tutanota-desktop.desktop";
      };
    };
  };

  gtk.iconCache.enable = true;

  qt = {
    enable = true;
  };

  catppuccin = {
    enable = true;

    enableReleaseCheck = true;
    cache.enable = true;

    autoEnable = true;
    flavor = "mocha";
    accent = "lavender";

    grub.enable = false; # Done Manually Instead

    tty = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
    };

    plymouth.enable = false; # Done Manually Instead

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

    fish = {
      enable = true;

      flavor = config.catppuccin.flavor;
    };

    gtk.icon.enable = false;

    fcitx5 = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;

      enableRounded = true;
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
    manageLingering = true;

    defaultUserShell = config.programs.fish.package;

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
          "adbusers" # Not Listed in builtins.attrNames config.users.groups
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

        linger = true;

        useDefaultShell = true;
      };
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
            enableFishIntegration = true;
          };

          preferXdgDirectories = true;

          pointerCursor = {
            name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
            size = builtins.floor (design_factor * 1.50); # 24

            hyprcursor = {
              enable = true;
              size = config.home-manager.users.normal.home.pointerCursor.size;
            };

            gtk = {
              enable = true;
              size = config.home-manager.users.normal.home.pointerCursor.size;
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
            pcall(require, "monitors") -- Import if available.
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
                    hl.exec_cmd("pidof soteria || uwsm-app -- soteria") -- Fallback

                    hl.exec_cmd("uwsm-app -- cursor-clip --daemon")
                  end
                '')
              ];
            };

            bind = [
              {
                _args = [
                  "SUPER + L"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-bar -p center -t 'bar.json' -s 'style.css'\")")
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
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-drawer -ovl -closebtn none -c 8 -g ${config.home-manager.users.normal.gtk.theme.name} -i ${config.home-manager.users.normal.gtk.iconTheme.name} -pbuseicontheme -lang en -k -wm uwsm -term ptyxis -fm nemo\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + RETURN"
                  (lib.generators.mkLuaInline "hl.dsp.exec_raw(\"bash -ic 'commands'\")") # Alias Requires Interactive Shell
                ];
              }
              {
                _args = [
                  "SUPER + SPACE"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- cursor-clip\")")
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
                  "SUPER + P"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- psono\")")
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
                  "SUPER + W"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"firefox-devedition --new-window\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + W"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"firefox-devedition --private-window\")")
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
                  "XF86MonBrightnessUp"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl set 1%+\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86MonBrightnessDown"
                  (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl set 1%-\")")
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
            ]; # TODO: Sort

            config = {
              binds = {
                allow_workspace_cycles = false;
                workspace_back_and_forth = false;
                hide_special_on_workspace_change = false;

                window_direction_monitor_fallback = true;
                ignore_group_lock = false;
                movefocus_cycles_groupfirst = true;
                movefocus_cycles_fullscreen = false;
                allow_pin_fullscreen = true;

                disable_keybind_grabbing = true;
                pass_mouse_when_bound = false;
              };

              cursor = {
                invisible = false;
                hide_on_key_press = false;
                hide_on_tablet = false;
                hide_on_touch = true;

                no_hardware_cursors = 2; # 2 = Automatic (Disabled When Tearing)
                enable_hyprcursor = true;
                sync_gsettings_theme = true;

                no_warps = false;
                persistent_warps = true;
                warp_back_after_non_mouse_input = true;

                zoom_rigid = true;
                zoom_detached_camera = false;
                zoom_disable_aa = false;
              };

              decoration = {
                shadow = {
                  enabled = true;

                  sharp = false;
                };

                border_part_of_window = true;
                rounding = builtins.floor (design_factor / 2); # 8
                rounding_power = 4.0; # 4.0 = Squircle

                active_opacity = 1.0;
                fullscreen_opacity = 1.0;
                inactive_opacity = 1.0;

                dim_special = 0.25;
                dim_modal = true;
                dim_inactive = false;
                dim_strength = 0.0;

                blur = {
                  enabled = true;
                  new_optimizations = true;

                  special = true;
                  popups = true;
                  input_methods = true;

                  ignore_opacity = false;
                  xray = true;
                };

                glow = {
                  enabled = false;
                };

                motion_blur = {
                  enabled = false;
                };
              };

              animations = {
                enabled = true;

                workspace_wraparound = false;
              };

              dwindle = {
                use_active_for_splits = true;
                force_split = 0; # Follows Mouse
                smart_split = false;
                preserve_split = true;

                smart_resizing = true;
              };

              general = {
                allow_tearing = true;

                gaps_workspaces = 0;

                layout = "dwindle";

                gaps_in = builtins.floor (design_factor / 4); # 4
                gaps_out = {
                  top = builtins.floor (design_factor / 4); # 4
                  right = builtins.floor (design_factor / 4); # 4
                  bottom = builtins.floor (design_factor / 4); # 4
                  left = builtins.floor (design_factor / 4); # 4
                };

                float_gaps = builtins.floor (design_factor / 4); # 4

                border_size = 1;
                "col.inactive_border" = lib.mkLuaInline "colors.surface1";
                "col.active_border" = lib.mkLuaInline "colors.surface2";
                "col.nogroup_border" = lib.mkLuaInline "colors.surface1";
                "col.nogroup_border_active" = lib.mkLuaInline "colors.surface2";

                resize_on_border = true;
                hover_icon_on_border = true;

                no_focus_fallback = false;

                snap = {
                  enabled = true;

                  respect_gaps = true;
                  monitor_gap = builtins.floor (design_factor / 4); # 4
                  window_gap = builtins.floor (design_factor / 4); # 4

                  border_overlap = false;
                };

                modal_parent_blocking = true;

                locale = "en_US";
              };

              misc = {
                disable_watchdog_warning = false;
                disable_xdg_env_checks = false;
                disable_autoreload = false;
                disable_scale_notification = false;

                allow_session_lock_restore = true;
                session_lock_xray = false;

                key_press_enables_dpms = true;
                mouse_move_enables_dpms = true;
                vrr = 1; # 1 = On
                mouse_move_focuses_monitor = true;

                disable_splash_rendering = true;
                disable_hyprland_logo = true;

                close_special_on_empty = true;

                enable_swallow = true;

                name_vk_after_proc = true;
                enable_anr_dialog = true;

                exit_window_retains_fullscreen = false;

                focus_on_activate = true;
                layers_hog_keyboard_focus = true;

                always_follow_on_dnd = true;

                animate_mouse_windowdragging = true;
                animate_manual_resizes = true;

                middle_click_paste = true;

                font_family = fontPreferences.name.sans_serif;
              };

              xwayland = {
                enabled = true;
                create_abstract_socket = true;

                force_zero_scaling = true; # Sacle = 1
                use_nearest_neighbor = true;
              };

              render = {
                cm_enabled = true;
                cm_auto_hdr = 1; # 1 = Auto-switch to "cm, hdr" in fullscreen when needed.
                send_content_type = true;
                new_render_scheduling = true;
                xp_mode = false;
                commit_timing_enabled = true;
              };

              # layerrule = [ ];

              # windowrulev2 = [ ];

              input = {
                numlock_by_default = false;
                kb_layout = "us";

                force_no_accel = false;
                scroll_button_lock = true;
                natural_scroll = false;
                left_handed = false;

                special_fallthrough = false;

                follow_mouse = 1; # 1 = Cursor movement will always change focus to the window under the cursor.
                focus_on_close = 1; # 1 = When a window is closed, focus will shift to the window under the cursor.
                mouse_refocus = true;

                touchpad = {
                  disable_while_typing = true;

                  flip_x = false;
                  flip_y = false;

                  middle_button_emulation = false;
                  clickfinger_behavior = false;

                  tap_to_click = true;

                  tap_and_drag = true;
                  drag_3fg = 1; # 1 = 3 Fingers # 2 = 4 Fingers
                  drag_lock = 2; # 2 = Enabled Sticky

                  natural_scroll = true;
                };

                touchdevice = {
                  enabled = true;
                };

                tablet = {
                  left_handed = false;
                };

                tablettool = {
                  eraser_button_mode = 0; # 0 = Default Hardware Behavior
                };

                virtualkeyboard = {
                  release_pressed_on_close = true;
                };
              };

              group = {
                auto_group = false;

                merge_groups_on_drag = true;
                merge_groups_on_groupbar = true;

                group_on_movetoworkspace = false;
                merge_floated_into_tiled_on_groupbar = false;
                insert_after_current = true;
                focus_removed_window = true;

                groupbar = {
                  enabled = true;
                  stacked = false;

                  render_titles = true;
                  scrolling = true;
                  middle_click_close = false;

                  keep_upper_gap = true;
                  gradients = true;
                  blur = true;
                  round_only_edges = false;
                  gradient_round_only_edges = false;
                };
              };

              gestures = {
                workspace_swipe_create_new = true;
                workspace_swipe_forever = true;

                # Touchpad
                workspace_swipe_invert = false;

                # Touchscreen
                workspace_swipe_touch = true;
                workspace_swipe_touch_invert = false;
              };

              ecosystem = {
                enforce_permissions = false;

                no_update_news = false;
                no_donation_nag = false;
              };

              quirks = {
                prefer_hdr = 1; # 1 = Always
              };
            }; # TODO: Sort

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

            "nwg-bar/bar.json" = {
              enable = true;

              source = pkgs.writeText "nwg-bar.json" ''
                [
                  {
                    "label": "_Lock",
                    "exec": "loginctl lock-session",
                    "icon": "${pkgs.nwg-bar}/share/nwg-bar/images/system-lock-screen.svg"
                  },
                  {
                    "label": "_Exit",
                    "exec": "uwsm stop",
                    "icon": "${pkgs.nwg-bar}/share/nwg-bar/images/system-log-out.svg"
                  },
                  {
                    "label": "_Shutdown",
                    "exec": "systemctl -i poweroff",
                    "icon": "${pkgs.nwg-bar}/share/nwg-bar/images/system-shutdown.svg"
                  },
                  {
                    "label": "_Reboot",
                    "exec": "systemctl reboot",
                    "icon": "${pkgs.nwg-bar}/share/nwg-bar/images/system-reboot.svg"
                  }
                ]''; # FIXME: hyprshutdown Does Not Work

              target = "nwg-bar/bar.json";
              executable = null;
            };

            "nwg-bar/style.css" = {
              enable = true;

              source = pkgs.writeText "nwg-bar.css" ''
                window {
                  border: 1px solid rgb(88, 91, 112);
                  border-radius: ${toString (builtins.floor (design_factor / 2))}px;
                }

                #bar {
                  margin: ${toString (builtins.floor (design_factor * 2))}px;
                  font-size: ${toString (builtins.floor design_factor)}px;
                  font-family: ${fontPreferences.name.sans_serif};
                }

                button,
                image {
                  box-shadow: none;
                  border-style: none;
                  background: none;
                  color: rgb(205, 214, 244);
                }

                button {
                  margin: ${toString (builtins.floor (design_factor / 4))}px;
                  padding-top: ${toString (builtins.floor (design_factor / 2))}px;
                }

                button:hover {
                  background-color: rgb(49, 50, 68);
                }

                button:focus {
                  background-color: rgb(49, 50, 68);
                }

                grid {
                  box-shadow: 0 0 ${toString (builtins.floor (design_factor * 3))}px rgb(49, 50, 68);
                  border-radius: ${toString (builtins.floor (design_factor / 2))}px;
                  background-color: rgb(17, 17, 27);
                  padding: ${toString (builtins.floor (design_factor / 2))}px;
                }'';
              # Catppuccin Mocha
              # "Surface 2" rgb(88, 91, 112)
              # "Text" rgb(205, 214, 244)
              # "Surface 0" rgb(49, 50, 68)
              # "Crust" rgb(17, 17, 27)

              target = "nwg-bar/style.css";
              executable = null;
            };

            "qBittorrent/themes/catppuccin-${config.catppuccin.flavor}.qbtheme" = {
              enable = true;

              source = builtins.fetchurl {
                url = "https://github.com/catppuccin/qbittorrent/releases/latest/download/catppuccin-${config.catppuccin.flavor}.qbtheme";
              };

              target = "qBittorrent/themes/catppuccin-${config.catppuccin.flavor}.qbtheme";
              executable = null;
            }; # Looks Weird
          };

          dataFile = {
            "imhex/themes/catppuccin-${config.catppuccin.flavor}.json" = {
              enable = true;

              source = builtins.fetchurl {
                url = "https://raw.githubusercontent.com/catppuccin/imhex/refs/heads/main/themes/catppuccin-${config.catppuccin.flavor}.json";
              };

              target = "imhex/themes/catppuccin-${config.catppuccin.flavor}.json";
              executable = null;
            };

            "SourceGit/Catppuccin_${lib.strings.toUpper (builtins.substring 0 1 config.catppuccin.flavor)}${
              builtins.substring 1 255 config.catppuccin.flavor
            }.json" =
              {
                enable = true;

                source = builtins.fetchurl {
                  url = "https://raw.githubusercontent.com/sourcegit-scm/sourcegit-theme/refs/heads/main/themes/Catpuccin_Mocha.json";
                };

                target = "SourceGit/Catppuccin_${
                  lib.strings.toUpper (builtins.substring 0 1 config.catppuccin.flavor)
                }${builtins.substring 1 255 config.catppuccin.flavor}.json";
                executable = null;
              }; # Non-Standard Path
          };

          # stateFile = { };

          # cacheFile = { };
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
            name = config.home-manager.users.normal.home.pointerCursor.name;
            size = config.home-manager.users.normal.home.pointerCursor.size;
          };

          gtk4 = {
            enable = true;

            colorScheme = config.home-manager.users.normal.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };

          gtk3 = {
            enable = true;

            colorScheme = config.home-manager.users.normal.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };

          gtk2 = {
            enable = true;

            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
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
              style = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.style;
              color_scheme_path = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.color_scheme_path;
              standard_dialogs = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.standard_dialogs;
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

          swaync = {
            enable = true;
            package = pkgs.swaynotificationcenter;
          };

          udiskie = {
            enable = true;
            package = pkgs.udiskie;

            automount = true;
            tray = "always";
            notify = true;

            settings = {
              terminal = "${config.xdg.terminal-exec.package}/bin/xdg-terminal-exec -d"; # TODO: Check
              file_manager = "${pkgs.xdg-utils}/bin/xdg-open";

              menu = "nested";

              password_cache = 5; # 5 Minutes
            };
          };

          poweralertd.enable = true;

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

          wayvnc = {
            enable = config.programs.wayvnc.enable;
            package = config.programs.wayvnc.package;

            settings = {
              address = "127.0.0.1";
              port = 5901;
            };

            autoStart = true;
          };
        };

        programs = {
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

          waybar = {
            enable = true;
            package = config.programs.waybar.package;

            systemd = {
              enable = true;

              enableInspect = false;
              enableDebug = false;
            };

            settings = {
              top_bar = {
                start_hidden = false;
                reload_style_on_change = true;
                position = "top";
                exclusive = true;
                layer = "top";
                passthrough = false;
                fixed-center = true;
                spacing = builtins.floor (design_factor / 4); # 4

                modules-left = [
                  "group/backlight-and-ppd-and-idle-inhibitor"
                  "group/pulseaudio-and-bluetooth"
                  "group/hardware-statistics"
                  "network"
                  "privacy"
                ];

                modules-center = [
                  "clock"
                ];

                modules-right = [
                  "group/swaync-and-systemd"
                  "tray"
                  "group/workspaces-and-taskbar"
                ];

                clock = {
                  timezone = config.time.timeZone;
                  locale = "en_US";
                  interval = 1;

                  format = "{:%I:%M %p}";
                  format-alt = "{:%A, %B %d, %Y}";

                  tooltip = true;
                  tooltip-format = "<tt><small>{calendar}</small></tt>";

                  calendar = {
                    mode = "year";
                    mode-mon-col = 3;
                    weeks-pos = "right";

                    format = {
                      months = "<b>{}</b>";
                      days = "{}";
                      weekdays = "<b>{}</b>";
                      weeks = "<i>{:%U}</i>";
                      today = "<u>{}</u>";
                    };
                  };
                };

                "group/backlight-and-ppd-and-idle-inhibitor" = {
                  modules = [
                    "backlight"
                    "power-profiles-daemon"
                    "idle_inhibitor"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = 500;
                  };
                  orientation = "inherit";
                };

                backlight = {
                  interval = 1;

                  format = "{percent}% {icon}";
                  format-icons = [
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                    ""
                  ];

                  tooltip = true;
                  tooltip-format = "{percent}% {icon}";

                  on-scroll-up = "brightnessctl set +1%";
                  on-scroll-down = "brightnessctl set 1%-";
                  reverse-scrolling = false;
                  reverse-mouse-scrolling = false;
                  scroll-step = 1.0;

                  on-click = "uwsm-app -- nwg-displays & uwsm-app -- com.sidevesh.Luminance";
                };

                power-profiles-daemon = {
                  format = "{icon}";
                  format-icons = {
                    performance = "";
                    balanced = "";
                    power-saver = "";
                  };

                  tooltip = true;
                  tooltip-format = "Driver: {driver}\nProfile: {profile}";
                };

                idle_inhibitor = {
                  start-activated = false;

                  format = "{icon}";
                  format-icons = {
                    activated = "";
                    deactivated = "";
                  };

                  tooltip = true;
                  tooltip-format-activated = "{status}";
                  tooltip-format-deactivated = "{status}";
                };

                "group/pulseaudio-and-bluetooth" = {
                  modules = [
                    "pulseaudio"
                    "bluetooth"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = 500;
                  };
                  orientation = "inherit";
                };

                pulseaudio = {
                  format = "{volume}% {icon} {format_source}";
                  format-muted = "{icon} {format_source}";

                  format-bluetooth = "{volume}% {icon} 󰂱 {format_source}";
                  format-bluetooth-muted = "{icon} 󰂱 {format_source}";

                  format-source = " {volume}% ";
                  format-source-muted = "";

                  format-icons = {
                    default = [
                      ""
                      ""
                      ""
                    ];
                    default-muted = "";

                    speaker = "󰓃";
                    speaker-muted = "󰓄";

                    headphone = "󰋋";
                    headphone-muted = "󰟎";

                    headset = "󰋎";
                    headset-muted = "󰋐";

                    hands-free = "󰏳";
                    hands-free-muted = "󰗿";

                    phone = "";
                    phone-muted = "";

                    portable = "";
                    portable-muted = "";

                    hdmi = "󰽟";
                    hdmi-muted = "󰽠";

                    hifi = "󰴸";
                    hifi-muted = "󰓄";

                    car = "󰄋";
                    car-muted = "󰸜";
                  };

                  tooltip = true;
                  tooltip-format = "{desc}";

                  scroll-step = 1.0;
                  reverse-scrolling = false;
                  reverse-mouse-scrolling = false;
                  max-volume = 100;
                  on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+";
                  on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";

                  on-click = "uwsm-app -- pwvucontrol & uwsm-app -- helvum";
                };

                bluetooth = {
                  format = "{status} {icon}";
                  format-disabled = "Disabled {icon}";
                  format-off = "Off {icon}";
                  format-on = "On {icon}";
                  format-connected = "{device_alias} {icon}";
                  format-connected-battery = "{device_alias} 󰂱 ({device_battery_percentage}%)";
                  format-icons = {
                    no-controller = "󰂲";
                    disabled = "󰂲";
                    off = "󰂲";
                    on = "󰂯";
                    connected = "󰂱";
                  };

                  tooltip = true;
                  tooltip-format = "Status: {status}\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}";
                  tooltip-format-disabled = "Status: Disabled";
                  tooltip-format-off = "Status: Off";
                  tooltip-format-on = "Status: On\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}";
                  tooltip-format-connected = "Status: Connected\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}\nConnected Devices ({num_connections}): {device_enumerate}";
                  tooltip-format-connected-battery = "Status: Connected\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}\nConnected Devices ({num_connections}): {device_enumerate}";
                  tooltip-format-enumerate-connected = "\n\tAddress: {device_address} ({device_address_type})\n\tAlias: {device_alias}";
                  tooltip-format-enumerate-connected-battery = "\n\tAddress: {device_address} ({device_address_type})\n\tAlias: {device_alias}\n\tBattery: {device_battery_percentage}%";

                  on-click = "uwsm-app -- overskride";
                };

                "group/hardware-statistics" = {
                  modules = [
                    "battery"
                    "cpu"
                    "memory"
                    "disk"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = 500;
                  };
                  orientation = "inherit";
                };

                battery = {
                  design-capacity = false;
                  weighted-average = true;
                  interval = 1;

                  full-at = 100;
                  states = {
                    warning = 25;
                    critical = 10;
                  };

                  format = "{capacity}% {icon}";
                  format-plugged = "{capacity}% ";
                  format-charging = "{capacity}% ";
                  format-full = "{capacity}% {icon}";
                  format-alt = "{time} {icon}";
                  format-time = "{H} h {m} min";
                  format-icons = [
                    ""
                    ""
                    ""
                    ""
                    ""
                  ];

                  tooltip = true;
                  tooltip-format = "Capacity: {capacity}%\nPower: {power} W\n{timeTo}\nCycles: {cycles}\nHealth: {health}%";

                  on-click = "uwsm-app -- resources";
                };

                cpu = {
                  interval = 1;

                  format = "{usage}% ";

                  tooltip = true;

                  on-click = "uwsm-app -- resources";
                };

                memory = {
                  interval = 1;

                  format = "{percentage}% ";

                  tooltip = true;
                  tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                  on-click = "uwsm-app -- resources";
                };

                disk = {
                  path = "/";
                  unit = "GB";
                  interval = 1;

                  format = "{percentage_used}% 󰋊";

                  tooltip = true;
                  tooltip-format = "Total: {specific_total} GB\nUsed: {specific_used} GB ({percentage_used}%)\nFree: {specific_free} GB ({percentage_free}%)";

                  on-click = "uwsm-app -- resources";
                };

                network = {
                  interval = 1;

                  format = "{bandwidthUpBytes} {bandwidthDownBytes}";
                  format-disconnected = "Disconnected 󱘖";
                  format-linked = "No IP 󰀦";
                  format-ethernet = "{bandwidthUpBytes}   {bandwidthDownBytes}";
                  format-wifi = "{bandwidthUpBytes}   {bandwidthDownBytes}";

                  tooltip = true;
                  tooltip-format = "Interface: {ifname}\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation: {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";
                  tooltip-format-disconnected = "Disconnected";
                  tooltip-format-ethernet = "Interface: {ifname}\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation= {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";
                  tooltip-format-wifi = "Interface: {ifname}\nESSID: {essid}\nFrequency: {frequency} GHz\nStrength: {signaldBm} dBm ({signalStrength}%)\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation: {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";

                  on-click = "uwsm-app -- nmgui & uwsm-app -- nm-connection-editor";
                };

                privacy = {
                  icon-size = fontPreferences.size;
                  icon-spacing = builtins.floor (design_factor * 0.50); # 8
                  transition-duration = 200;

                  modules = [
                    {
                      type = "screenshare";
                      tooltip = true;
                      tooltip-icon-size = fontPreferences.size;
                    }
                    {
                      type = "audio-in";
                      tooltip = true;
                      tooltip-icon-size = fontPreferences.size;
                    }
                  ];
                }; # FIXME: Do Not Work

                "group/swaync-and-systemd" = {
                  modules = [
                    "custom/swaync"
                    "systemd-failed-units"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = false;
                    transition-duration = 500;
                  };
                  orientation = "inherit";
                };

                "custom/swaync" = {
                  format = "{} {icon}";
                  format-icons = {
                    notification = "<span foreground=\"@yellow\"><sup></sup></span>";
                    none = "";

                    inhibited-notification = "<span foreground=\"@yellow\"><sup></sup></span>";
                    inhibited-none = "";

                    dnd-notification = "<span foreground=\"@yellow\"><sup></sup></span>";
                    dnd-none = "";

                    dnd-inhibited-notification = "<span foreground=\"@yellow\"><sup></sup></span>";
                    dnd-inhibited-none = "";
                  };

                  tooltip = false;

                  return-type = "json";
                  exec-if = "which swaync-client";
                  exec = "swaync-client -swb";
                  on-click = "swaync-client -t -sw";
                  on-click-right = "swaync-client -d -sw";
                  escape = true;
                }; # FIXME

                systemd-failed-units = {
                  system = true;
                  user = true;

                  hide-on-ok = false;

                  format = "{nr_failed_system}, {nr_failed_user} ";
                  format-ok = "";

                  on-click = "uwsm-app -- xdg-terminal-exec systemctl-tui";
                };

                tray = {
                  show-passive-items = true;
                  reverse-direction = false;
                  icon-size = fontPreferences.size;
                  spacing = builtins.floor (design_factor / 4); # 4
                };

                "group/workspaces-and-taskbar" = {
                  modules = [
                    "hyprland/workspaces"
                    "wlr/taskbar"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = false;
                    transition-duration = 500;
                  };
                  orientation = "inherit";
                };

                "hyprland/workspaces" = {
                  all-outputs = false;
                  show-special = true;
                  special-visible-only = false;
                  active-only = false;
                  format = "{name}";
                  move-to-monitor = false;

                  on-click = "activate"; # FIXME: Does Not Work
                };

                "wlr/taskbar" = {
                  all-outputs = false;
                  active-first = false;
                  sort-by-app-id = false;
                  format = "{icon}";
                  icon-size = fontPreferences.size;
                  markup = true;

                  tooltip = true;
                  tooltip-format = "Title: {title}\nName: {name}\nID: {app_id}\nState: {state}";

                  on-click = "activate";
                };
              };
            };

            style = ''
              * {
                font-family: ${fontPreferences.name.sans_serif};
                font-size: ${toString fontPreferences.size}px;
              }

              window#waybar {
                border: none;
                background-color: transparent;
              }

              .modules-right > widget:last-child > #workspaces {
                margin-right: 0px;
              }

              .modules-left > widget:first-child > #workspaces {
                margin-left: 0px;
              }

              #backlight,
              #power-profiles-daemon,
              #idle_inhibitor,
              #pulseaudio,
              #bluetooth,
              #battery,
              #cpu,
              #memory,
              #disk,
              #network,
              #clock,
              #systemd-failed-units,
              #custom-swaync,
              #privacy,
              #window {
                border-radius: ${toString design_factor}px;
                background-color: @crust;
                padding: ${toString (builtins.floor (design_factor / 8))}px ${
                  toString (builtins.floor (design_factor / 2))
                }px;
                color: @text;
              }

              #power-profiles-daemon,
              #idle_inhibitor,
              #bluetooth,
              #cpu,
              #memory,
              #disk {
                margin-left: ${toString (builtins.floor (design_factor / 4))}px;
              }

              #systemd-failed-units {
                margin-right: ${toString (builtins.floor (design_factor / 4))}px;
              }

              #power-profiles-daemon.power-saver {
                color: @mauve;
              }

              #power-profiles-daemon.balanced {
                color: @blue;
              }

              #power-profiles-daemon.performance {
                color: @lavender;
              }

              #idle_inhibitor.deactivated {
                color: @text;
              }

              #idle_inhibitor.activated {
                color: @green;
              }

              #pulseaudio.muted,
              #pulseaudio.source-muted {
                color: @red;
              }

              #pulseaudio.bluetooth {
                color: @text;
              }

              #bluetooth.no-controller,
              #bluetooth.disabled,
              #bluetooth.off {
                color: @red;
              }

              #bluetooth.on,
              #bluetooth.discoverable,
              #bluetooth.pairable {
                color: @text;
              }

              #bluetooth.discovering,
              #bluetooth.connected {
                color: @green;
              }

              #battery.plugged,
              #battery.full {
                color: @text;
              }

              #battery.charging {
                color: @green;
              }

              #battery.warning {
                color: @peach;
              }

              #battery.critical {
                color: @red;
              }

              #network.disabled,
              #network.disconnected,
              #network.linked {
                color: @red;
              }

              #network.etherenet,
              #network.wifi {
                color: @text;
              }

              #systemd-failed-units.ok {
                color: @text;
              }

              #systemd-failed-units.degraded {
                color: @red;
              }

              #custom-swaync {
                font-family: ${fontPreferences.name.mono};
              }

              #privacy-item.audio-in,
              #privacy-item.screenshare {
                color: @green;
              }

              #workspaces,
              #taskbar,
              #tray {
                background-color: transparent;
              }

              button {
                margin: 0px ${toString (builtins.floor (design_factor / 8))}px;
                border-radius: ${toString design_factor}px;
                background-color: @crust;
                padding: 0px;
                color: @text;
              }

              button * {
                padding: 0px ${toString (builtins.floor (design_factor / 4))}px;
              }

              button.active {
                background-color: @mantle;
              }

              button:hover {
                background-color: @surface0;
              }

              #window label {
                padding: 0px ${toString (builtins.floor (design_factor / 4))}px;
                font-size: ${toString fontPreferences.size}px;
              }

              #tray > widget {
                border-radius: ${toString design_factor}px;
                background-color: @crust;
                color: @text;
              }

              #tray image {
                padding: 0px ${toString (builtins.floor (design_factor / 2))}px;
              }

              #tray > .passive {
                -gtk-icon-effect: dim;
              }

              #tray > .active {
                background-color: @mantle;
              }

              #tray > .needs-attention {
                background-color: @green;
                -gtk-icon-effect: highlight;
              }

              #tray > widget:hover {
                background-color: @surface0;
              }
            '';
          };

          ptyxis = {
            enable = true;
            package = pkgs.ptyxis;
          };

          bash = {
            enable = true;
            package = pkgs.bashInteractive;

            enableVteIntegration = config.programs.bash.vteIntegration;
            enableCompletion = config.programs.bash.completion.enable;

            # sessionVariables = { };

            shellAliases = config.programs.bash.shellAliases;

            # profileExtra = '''';

            # initExtra = '''';

            # logoutExtra = '''';
          };

          fish = {
            enable = config.programs.fish.enable;
            package = config.programs.fish.package;

            plugins = with pkgs.fishPlugins; [
              {
                name = "autopair";
                src = autopair.src;
              }
              {
                name = "bang-bang";
                src = bang-bang.src;
              }
              {
                name = "colored-man-pages";
                src = colored-man-pages.src;
              }
              {
                name = "done";
                src = done.src;
              }
              {
                name = "fish-bd";
                src = fish-bd.src;
              }
              {
                name = "fish-you-should-use";
                src = fish-you-should-use.src;
              }
              {
                name = "foreign-env";
                src = foreign-env.src;
              }
              {
                name = "humantime-fish";
                src = humantime-fish.src;
              }
              {
                name = "puffer";
                src = puffer.src;
              }
              {
                name = "spark";
                src = spark.src;
              }
            ];

            generateCompletions = config.programs.fish.generateCompletions;

            shellAbbrs = config.programs.fish.shellAbbrs;
            shellAliases = config.programs.fish.shellAliases;
            preferAbbrs = false;

            loginShellInit = config.programs.fish.loginShellInit;
            shellInit = config.programs.fish.shellInit;
            interactiveShellInit = config.programs.fish.interactiveShellInit;

            # shellInitLast = '''';
          };

          nix-your-shell = {
            enable = true;
            package = pkgs.nix-your-shell;

            enableFishIntegration = true;

            nix-output-monitor = {
              enable = true;
              package = pkgs.nix-output-monitor;
            };
          };

          starship = {
            enable = config.programs.starship.enable;
            package = config.programs.starship.package;

            # extraPackages = with pkgs; [ ];

            enableBashIntegration = true;
            enableFishIntegration = true;

            enableInteractive = config.programs.starship.interactiveOnly;

            presets = config.programs.starship.presets;
            settings = config.programs.starship.settings;
          };

          nix-index = {
            enable = config.programs.nix-index.enable;
            package = config.programs.nix-index.package;

            enableBashIntegration = config.programs.nix-index.enableBashIntegration;
            enableFishIntegration = config.programs.nix-index.enableFishIntegration;
          };

          command-not-found.enable = config.programs.command-not-found.enable;

          tirith = {
            enable = true;
            package = pkgs.tirith;

            enableBashIntegration = true;
            enableFishIntegration = true;
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
            enableFishIntegration = true;
          };

          vivid = {
            enable = true;
            package = pkgs.vivid;

            enableBashIntegration = true;
            enableFishIntegration = true;

            colorMode = "24-bit";
            activeTheme = "catppuccin-${config.catppuccin.flavor}";
          };

          direnv = {
            enable = config.programs.direnv.enable;
            package = config.programs.direnv.package;

            nix-direnv = {
              enable = config.programs.direnv.nix-direnv.enable;
              package = config.programs.direnv.nix-direnv.package;
            };

            enableBashIntegration = config.programs.direnv.enableBashIntegration;
            enableFishIntegration = config.programs.direnv.enableFishIntegration;

            silent = config.programs.direnv.silent;
          };

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

          # texlive = { };

          jq = {
            enable = true;
            package = (
              pkgs.jq.override {
                onigurumaSupport = true;
              }
            );
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

          television = {
            enable = config.programs.television.enable;
            package = config.programs.television.package;

            enableBashIntegration = config.programs.television.enableBashIntegration;
            enableFishIntegration = config.programs.television.enableFishIntegration;
          };

          mcp = {
            enable = true;
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
                config.programs.evince.package
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
              "fish"
              "flutter-snippets"
              "git-firefly"
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
                font_size = builtins.floor design_factor;
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

                env = {
                  GIT_EDITOR = "zed --wait";
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
              ui_font_size = builtins.floor design_factor;

              buffer_font_family = fontPreferences.name.mono;
              buffer_font_size = builtins.floor design_factor;
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

                "Git Attributes" = [
                  "**/{git,.git,.git/info}/attributes"
                ];
                "Git Config" = [
                  "*.gitconfig"
                  "**/{git,.git,.git/modules,.git/modules/*}/config"
                ];
                "Git Ignore" = [
                  "**/{git,.git}/ignore"
                  "**/.git/info/exclude"
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
                      # # Or
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
                # }; # FIXME: Errors

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
                        executable = "evince-synctex";
                        args = [
                          "-f"
                          "%l"
                          "%p"
                          "\"texlab -i %f -l %l\""
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

          bat = {
            enable = config.programs.bat.enable;
            package = config.programs.bat.package;
            extraPackages = config.programs.bat.extraPackages;
          };

          chromium = {
            enable = true;
            package = pkgs.cromite; # From config.nixpkgs.overlays

            dictionaries = with pkgs.hunspellDictsChromium; [
              en_US
            ];
          };

          firefox = {
            enable = config.programs.firefox.enable;
            package = config.programs.firefox.package;

            languagePacks = config.programs.firefox.languagePacks;

            policies = config.programs.firefox.policies;
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

          keychain = {
            enable = true;
            package = pkgs.keychain;

            enableBashIntegration = true;
            enableFishIntegration = true;

            enableXsessionIntegration = false;
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

          onlyoffice = {
            enable = true;
            package = pkgs.onlyoffice-desktopeditors;
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
                config.home-manager.users.normal.programs.mangohud.package
              ];
            winePackages = with pkgs; [
              wineWow64Packages.waylandFull
            ];
            protonPackages = with pkgs; [
              proton-ge-bin
            ];
          };

          mangohud = {
            enable = true;
            package = pkgs.mangohud;
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

          obs-studio = {
            enable = config.programs.obs-studio.enable;
            package = config.programs.obs-studio.package;
            plugins = config.programs.obs-studio.plugins;
          };

          ssh = {
            enable = true;
            package = config.services.openssh.package;

            enableDefaultConfig = false;
          };

          man = {
            enable = config.documentation.man.enable;
            package = config.documentation.man.man-db.package;
            man-db.enable = config.documentation.man.man-db.enable;

            generateCaches = config.documentation.man.cache.enable;
          };

          info = {
            enable = true;
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

          hyprtoolkit = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          hyprland = {
            enable = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          hyprlock = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            useDefaultConfig = true;
          };

          cursors = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          gtk.icon.enable = false;

          qt5ct = {
            enable = config.catppuccin.enable;
            assertPlatformTheme = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          kvantum = {
            enable = config.catppuccin.enable;
            assertStyle = true;
            apply = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          waybar = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            mode = "prependImport";
          };

          swaync = {
            enable = true;

            flavor = config.catppuccin.flavor;

            font = fontPreferences.name.sans_serif;
            fontSize = toString fontPreferences.size;
          };

          fish = {
            enable = config.catppuccin.fish.enable;

            flavor = config.catppuccin.flavor;
          };

          starship = {
            enable = true;

            flavor = config.catppuccin.flavor;
          };

          fcitx5 = {
            enable = config.catppuccin.enable;
            apply = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            enableRounded = true;
          };

          vivid = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          television = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
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

          bat = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          firefox = {
            enable = config.catppuccin.enable;
            force = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          }; # FIXME: Does Not Work

          delta = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
          };

          gh-dash = {
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
        }; # From catppuccinThemeFlake

        manual = {
          manpages.enable = true;
          html.enable = true;
          json.enable = false;
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
