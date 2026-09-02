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
  # stableNixPackages =
  #   import
  #     (fetchTarball {
  #       url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-26.05.tar.gz";
  #     })
  #     {
  #       config = config.nixpkgs.config;
  #     };

  grubThemeFlake = builtins.getFlake "github:jeslie0/nixos-grub-themes/main";
  homeManagerFlake = builtins.getFlake "github:nix-community/home-manager/master";
  catppuccinThemeFlake = builtins.getFlake "github:catppuccin/nix";

  # p="$(nix eval --raw nixpkgs#path)/pkgs/development/mobile/androidenv/querypackages.sh"; for t in packages images addons extras licenses; do sh "$p" "$t"; done
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    numLatestPlatformVersions = 1;
    platformVersions = [
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
      "37.1"
      "latest"
    ];
    useGoogleAPIs = false;
    useGoogleTVAddOns = false;

    platformToolsVersion = "latest";
    buildToolsVersions = [
      "35.0.0"
      "36.0.0"
      "36.1.0"
      "37.0.0"
      "latest"
    ];

    includeNDK = true;
    ndkVersions = [
      "28.2.13676358"
      "29.0.14206865"
      "latest"
    ];

    cmdLineToolsVersion = "latest";
    toolsVersion = "latest";

    includeCmake = true;
    cmakeVersions = [
      "3.22.1"
      "4.1.2"
      "latest"
    ];

    includeExtras = [
      "extras;google;auto"
      "extras;google;simulators"
    ];

    includeEmulator = true;
    emulatorVersion = "latest";

    includeSystemImages = false; # Disabled because it includes all from platformVersions
    systemImageTypes = [
      "default" # Vanilla
    ];
    abiVersions =
      pkgs.lib.optionals (config.nixpkgs.hostPlatform.system == "x86_64-linux") [
        "x86_64"
      ]
      ++ pkgs.lib.optionals (config.nixpkgs.hostPlatform.system == "aarch64-linux") [
        "arm64-v8a"
        "armeabi-v7a"
      ];

    includeSources = false;
  };

  fontPreferences = {
    package = pkgs.nerd-fonts.noto;

    name = {
      monospace = "NotoMono Nerd Font Mono";
      sansSerif = "NotoSans Nerd Font";
      serif = "NotoSerif Nerd Font";
      emoji = "Noto Color Emoji";
    };

    size = 12;
  };

  tlsCertificateFiles =
    pkgs.runCommand "generate_tls_certificate"
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

  bgrtBmp = builtins.path {
    path = "/sys/firmware/acpi/bgrt/image";
    name = "bgrt.bmp";
  };

  bgrtPng =
    pkgs.runCommand "BGRT.png"
      {
        nativeBuildInputs = with pkgs; [
          imagemagick
        ];
      }
      ''
        magick BMP:${bgrtBmp} \
          -fuzz 16% \
          -transparent black \
          -background "#1e1e2e" \
          -resize 1920x1080\> \
          -gravity center \
          -extent 1920x1080 \
          $out
      '';
  # It assumes that the background of BGRT is black and that 16% fuzz is sufficient.
  # Catppuccin Mocha: "Base" #1e1e2e

  transparent_1x1_png_file = builtins.fetchurl {
    url = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png";
  };

  designFactor = 16;
  transitionDuration = 500; # 500 Milliseconds
in
{
  _class = "nixos";

  imports = [
    homeManagerFlake.nixosModules.home-manager
    catppuccinThemeFlake.nixosModules.catppuccin

    ./hardware-and-user-configuration.nix
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
      # max-jobs = 1;
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
    hostPlatform = {
      system = "${config.specificHardwareConfiguration.systemArchitecture}-linux";
    };

    config = {
      allowAliases = false;
      allowUnfree = true;

      permittedInsecurePackages = pkgs.lib.optionals config.nixpkgs.config.allowUnfree [
        "ventoy-gtk3-1.1.17"
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
                cp ${bgrtPng} $out/background.png

                rm -f $out/logo.png
                sed -i '/# Logo image/,+5d' $out/theme.txt
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

                cp ${bgrtPng} $THEME_DIRECTORY/background.png

                sed -i 's/VerticalAlignment=.*/VerticalAlignment=.80/g' $THEME_DIRECTORY/catppuccin-${config.catppuccin.flavor}.plymouth
                sed -i 's/DialogVerticalAlignment=.*/DialogVerticalAlignment=.80/g' $THEME_DIRECTORY/catppuccin-${config.catppuccin.flavor}.plymouth
              ''; # installPhase Runs postInstall
            });
      })

      (final: previous: {
        hardinfo2 = previous.hardinfo2.override {
          printingSupport = true;
        };
      })

      (
        final: previous:
        let
          src = final.fetchurl {
            url =
              if config.nixpkgs.hostPlatform.system == "x86_64-linux" then
                "https://github.com/raindropio/desktop/releases/latest/download/Raindrop-x86_64.AppImage"
              else if config.nixpkgs.hostPlatform.system == "aarch64-linux" then
                "https://github.com/raindropio/desktop/releases/latest/download/Raindrop-arm64.AppImage"
              else
                throw "No ${config.nixpkgs.hostPlatform.system} AppImage for Raindrop.io!";

            hash = "sha256-wQJMFMQjkeMhOt2qE41cPKjjMgPNdpqQ3YGKtNWgvSk=";
          };

          raindropioExtracted = final.appimageTools.extract {
            pname = "raindropio";
            version = "latest";
            inherit src;
          };

          raindropio = final.appimageTools.wrapType2 {
            pname = "raindropio";
            version = "latest";
            inherit src;
          };

          raindropioDesktopFile = "${raindropioExtracted}/raindrop.desktop";
        in
        {
          inherit
            raindropio
            raindropioDesktopFile
            ;
        }
      ) # Addition

      (final: prev: {
        rtcqs = final.python3.pkgs.buildPythonApplication rec {
          pname = "rtcqs";
          version = "0.6.2";
          format = "pyproject";

          pythonRuntimeDepsCheckHook = "true";

          buildInputs = [
            final.python3.pkgs.setuptools
          ];

          src = final.fetchPypi {
            inherit pname version;
            hash = "sha256-DfeV9kGhdMf6hZ1iNJ0L3HUn7m8c1gRK5cjtJNUAvJI=";
          };
        };
      }) # Addition
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
        mkdir -p /usr/share/i18n
        ln -sfn /run/current-system/sw/share/i18n/locales /usr/share/i18n/locales
      '';

      copyOnlyOfficeFonts =
        let
          fonts = config.fonts.packages;
        in
        ''
          DIRECTORY="/var/lib/onlyoffice-fonts/"
          mkdir -p "$DIRECTORY"

          ${pkgs.lib.concatMapStrings (package: ''
            if [ -d "${package}/share/fonts" ]; then
              find "${package}/share/fonts" -type f \( \
                -name "*.bdf" -o \
                -name "*.otf" -o \
                -name "*.pcf" -o \
                -name "*.pfa" -o \
                -name "*.pfb" -o \
                -name "*.ttc" -o \
                -name "*.ttf" \
              \) -exec cp -f {} "$DIRECTORY" \;
            fi
          '') fonts}

          chmod -R 777 "$DIRECTORY"
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
        splashMode = "normal";

        theme = "${pkgs.catppuccin-grub}/"; # From config.nixpkgs.overlays
        splashImage = pkgs.lib.mkForce "${bgrtPng}";

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
        "dev.tty.ldisc_autoload" = 0;

        "fs.protected_fifos" = 2;
        "fs.protected_hardlinks" = 1;
        "fs.protected_regular" = 2;
        "fs.protected_symlinks" = 1;
        "fs.suid_dumpable" = 0;

        "kernel.core_uses_pid" = 1;
        "kernel.ctrl-alt-del" = 0;
        "kernel.dmesg_restrict" = 1;
        "kernel.kptr_restrict" = 2;
        "kernel.perf_event_paranoid" = 3;
        "kernel.randomize_va_space" = 2;
        "kernel.sysrq" = 0;
        "kernel.unprivileged_bpf_disabled" = 1;
        "kernel.yama.ptrace_scope" = 2;

        "net.core.default_qdisc" = "fq";
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.all.bootp_relay" = 0;
        "net.ipv4.conf.all.forwarding" = 0;
        "net.ipv4.conf.all.log_martians" = 1;
        "net.ipv4.conf.all.mc_forwarding" = 0;
        "net.ipv4.conf.all.proxy_arp" = 0;
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        "net.ipv4.conf.default.log_martians" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        "net.ipv4.conf.default.send_redirects" = 0;
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        "net.ipv4.icmp_ignore_bogus_error_responses" = 1;
        "net.ipv4.tcp_congestion_control" = "bbr";
        "net.ipv4.tcp_ecn" = 1;
        "net.ipv4.tcp_mtu_probing" = 1;
        "net.ipv4.tcp_syncookies" = 1;
        "net.ipv4.tcp_timestamps" = 1;
        "net.ipv4.tcp_tw_reuse" = 2;
        "net.ipv4.tcp_window_scaling" = 1;
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;

        "vm.swappiness" = 10;
      };
    };

    kernelPackages = pkgs.linuxKernel.packages.linux_xanmod_latest;

    extraModulePackages = with config.boot.kernelPackages; [
      apfs
      bcachefs
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
      "at24" # SDR/DDR/DDR2/DDR3 SPD and I²C
      "ee1004" # DDR4 SPD
      "spd5118" # DDR5 SPD
    ]
    ++ config.specificHardwareConfiguration.kernelModules; # From hardware-and-user-configuration.nix

    blacklistedKernelModules = [
      "efifb"
      "simplefb"
    ];

    extraModprobeConfig = ''
      options kvm ignore_msrs=1 report_ignored_msrs=0
    ''
    + config.specificHardwareConfiguration.boot.extraModprobeConfig; # From hardware-and-user-configuration.nix

    kernelParams = [
      "boot.shell_on_fail"
      "initcall_blacklist=simpledrm_platform_driver_init"
      "iommu=pt"
      "kvm.ignore_msrs=1"
      "mitigations=auto"
      "rd.systemd.show_status=true"
      "rd.udev.log_level=err"
      "splash"
      "threadirqs"
      "udev.log_level=err"
      "udev.log_priority=err"
    ]
    ++ config.specificHardwareConfiguration.boot.kernelParams; # From hardware-and-user-configuration.nix

    initrd = {
      enable = true;

      kernelModules = config.boot.kernelModules;
      availableKernelModules = [
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ]
      ++ config.specificHardwareConfiguration.boot.initrd.availableKernelModules; # From hardware-and-user-configuration.nix

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

    kexec.enable = false;
    crashDump.enable = false;

    consoleLogLevel = 4; # 4 = KERN_WARNING

    plymouth = {
      enable = true;

      themePackages = with pkgs; [
        catppuccin-plymouth # From config.nixpkgs.overlays
      ];
      theme = "catppuccin-${config.catppuccin.flavor}";

      font = "${pkgs.nerd-fonts.noto}/share/fonts/truetype/NerdFonts/Noto/NotoSansNerdFont-Regular.ttf";

      logo = transparent_1x1_png_file; # Due to zero margin between the logo and throbber, and because the shutdown screen does not render the logo like the boot screen.

      showDelay = 0;

      extraConfig = ''
        UseFirmwareBackground=false
      ''; # Done Manually Instead
    };
  };

  powerManagement = {
    enable = true;

    cpuFreqGovernor = "performance"; # Makes Power Profiles Daemon Ignored
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
      alsa-firmware
      linux-firmware
      sof-firmware
    ];

    firmwareCompression = "zstd";

    cpu = {
      "${config.specificHardwareConfiguration.cpuVendor}" = {
        updateMicrocode = true;
        microcodePackage = pkgs."microcode-${config.specificHardwareConfiguration.cpuVendor}";
      };
    };

    block = {
      scheduler = {
        "mmcblk[0-9]*" = "bfq";
        "nvme[0-9]*" = "none";
      };

      defaultScheduler = "none";
      defaultSchedulerExclude = "loop[0-9]*";
      defaultSchedulerRotational = "bfq";
    };

    i2c = {
      enable = true;
      group = "i2c";
    };

    alsa.enable = !config.services.pipewire.alsa.enable;

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = config.specificHardwareConfiguration.hardware.graphics.extraPackages; # From hardware-and-user-configuration.nix
      extraPackages32 = config.specificHardwareConfiguration.hardware.graphics.extraPackages32; # From hardware-and-user-configuration.nix
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

      hsphfpd.enable = !config.services.pipewire.wireplumber.enable;

      powerOnBoot = true;

      input = {
        General = {
          IdleTimeout = 0; # 0 = Disabled
          LEAutoSecurity = true;
          ClassicBondedOnly = true;
          UserspaceHID = true;
        };
      };

      network = {
        General = {
          DisableSecurity = false;
        };
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

  systemd = {
    package = (
      pkgs.systemd.override {
        withAcl = true;
        withCryptsetup = true;
        withDocumentation = config.documentation.enable;
        withLogind = true;
        withOpenSSL = true;
        withPam = true;
        withPolkit = true;
      }
    );

    settings = {
      Manager = {
        DefaultIOAccounting = true;
        DefaultIPAccounting = true;

        DefaultLimitNOFILE = 524288; # Esync
      };
    };

    tmpfiles.rules = [
      "L+ /lib/modules/ - - - - /run/current-system/kernel-modules/lib/modules/"

      "d /var/lib/swtpm-localca 0750 tss root -"
    ]
    ++ config.specificHardwareConfiguration.systemd.tmpfiles.rules;
  };

  zramSwap = {
    enable = true;

    algorithm = config.boot.tmp.zramSettings.compression-algorithm;
    swapDevices = 1;
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
          withInsults = true; # May Include Profanity
        }
      );

      execWheelOnly = true;
      wheelNeedsPassword = true;

      extraRules = [
        {
          users = [
            config.users.users.normal.name
          ];
          commands = [
            {
              command = "${pkgs.cpu-x}/bin/cpu-x";
              options = [
                "NOPASSWD"
                "SETENV"
              ];
            }
          ];
        }

        {
          users = [
            config.users.users.normal.name
          ];
          commands = [
            {
              command = "${pkgs.hardinfo2}/bin/hardinfo2";
              options = [
                "NOPASSWD"
                "SETENV"
              ];
            }
          ];
        }
      ];

      extraConfig = ''
        Defaults pwfeedback
      '';
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
        ly = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        login = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        hyprlock = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        vlock = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        su = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        sudo = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        polkit-1 = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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

        sshd = {
          unixAuth = true;
          fprintAuth = config.services.fprintd.enable;

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
      }; # ls /etc/pam.d/

      loginLimits = [
        {
          domain = "@audio";
          item = "memlock";
          type = "-";
          value = "unlimited";
        }

        {
          domain = "@audio";
          item = "rtprio";
          type = "-";
          value = "99";
        }

        {
          domain = "@audio";
          item = "nofile";
          type = "soft";
          value = "524288"; # 524288 > 99999
        }

        {
          domain = "@audio";
          item = "nofile";
          type = "hard";
          value = "524288"; # 524288 > 99999
        }

        {
          domain = config.users.users.normal.name;
          item = "nofile";
          type = "soft";
          value = "524288";
        } # Esync

        {
          domain = config.users.users.normal.name;
          item = "nofile";
          type = "hard";
          value = "524288";
        } # Esync
      ];
    };

    enableWrappers = true;
    wrappers = {
      spice-client-glib-usb-acl-helper = {
        source = "${
          (pkgs.spice-gtk.override {
            withPolkit = true;
          })
        }/bin/spice-client-glib-usb-acl-helper";
      };
    };

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
    hostName = "Bitscoper-WorkStation";
    fqdn = "${config.networking.hostName}.${config.networking.domain}";

    wireless = {
      dbusControlled = true;
      userControlled = true;
      enableHardening = true;
    };

    useDHCP = if config.networking.networkmanager.dhcp == "internal" then false else true;
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

  time = {
    hardwareClockInLocalTime = false;

    timeZone = null;
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

    inputMethod = {
      enable = true;

      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          fcitx5-openbangla-keyboard
        ];
        waylandFrontend = true;

        ignoreUserConfig = false;
      };

      enableGtk3 = true;
      enableGtk2 = true;
    };
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      package = (
        pkgs.libvirt.override {
          enableCeph = false; # FIXME: Build Failure
          enableGlusterfs = true;
          enableIscsi = true;
          enableXen = false;
          enableZfs = true;
        }
      );

      qemu = {
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
    journald = {
      audit = "keep";

      forwardToSyslog = false;
      storage = "persistent";
    };

    das_watchdog.enable = true;

    fstrim = {
      enable = true;
      interval = "weekly";
    };

    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
    };

    beesd = { };

    dbus = {
      enable = true;
      dbusPackage = (
        pkgs.dbus.override {
          enableSystemd = true;
        }
      );

      implementation = "broker";

      packages = with pkgs; [
        fprintd
        libvirt-dbus
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

    automatic-timezoned.enable = !config.services.tzupdate.enable;

    tzupdate = {
      enable = true;
      package = pkgs.tzupdate;

      timer = {
        enable = true;
        interval = "hourly";
      };
    };

    chrony = {
      enable = true;
      package = pkgs.chrony;

      enableMemoryLocking = true;

      servers = config.networking.timeServers;
      enableNTS = false;
      serverOption = "iburst";

      enableRTCTrimming = true;
      makestep = {
        enable = true;
      };
    };

    timesyncd.enable = !config.services.chrony.enable;

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

    logind = {
      settings = {
        Login = {
          killUserProcesses = true;

          lidSwitch = pkgs.lib.optionals config.services.upower.ignoreLid "ignore";
          lidSwitchDocked = pkgs.lib.optionals config.services.upower.ignoreLid "ignore";
          lidSwitchExternalPower = pkgs.lib.optionals config.services.upower.ignoreLid "ignore";

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

    acpid = {
      enable = true;

      # powerEventCommands = '''';
      # acEventCommands = '''';
      # lidEventCommands = '''';

      logEvents = false;
    };

    power-profiles-daemon.enable = !config.powerManagement.enable;
    tlp.enable = !config.powerManagement.enable;

    thermald = {
      enable = true;
      package = pkgs.thermald;

      ignoreCpuidCheck = false;

      debug = config.environment.enableDebugInfo;
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
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
        DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        SUBSYSTEM=="backlight", ACTION=="add", KERNEL=="*", MODE="0666" RUN+="${config.home-manager.users.normal.programs.dircolors.package}/bin/chmod a+w /sys/class/backlight/%k/brightness"
      '' # config.home-manager.users.normal.programs.dircolors.package = Overriden coreutils-full
      + config.specificHardwareConfiguration.services.udev.extraRules;
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

    xserver.enable = false;

    displayManager = {
      enable = true;

      ly = {
        enable = true;
        package = pkgs.ly;

        x11Support = config.programs.hyprland.xwayland.enable;
      };

      defaultSession = "hyprland-uwsm";

      autoLogin.enable = false;

      logToJournal = true;
    };

    accounts-daemon.enable = true;

    gnome.gnome-keyring.enable = true;

    fprintd = {
      enable = true;
      package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;

      tod = {
        enable = config.specificHardwareConfiguration.services.fprintd.tod.enable;
        driver = pkgs.lib.optionals config.services.fprintd.tod.enable config.specificHardwareConfiguration.services.fprintd.tod.package;
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

      # extraLv2Packages = with pkgs; [
      # ];

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

          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = false;
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
        gutenprint-bin
      ];

      cups-pdf.enable = false;

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

      debugLevel = 0; # 0 = Disabled
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
          Banner = pkgs.lib.toString banner;
          LogLevel = "ERROR";
          PasswordAuthentication = true;
          PermitRootLogin = "yes";
          StrictModes = true;
          UseDns = true;
          X11Forwarding = config.programs.hyprland.xwayland.enable;
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

      syncModels = false;

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
    uwsm = {
      enable = true;
      package = (
        pkgs.uwsm.override {
          fumonSupport = true;
          uuctlSupport = false;
          uwsmAppSupport = true;
        }
      );
    };

    hyprland = {
      enable = true;
      package = (
        pkgs.hyprland.override {
          debug = config.environment.enableDebugInfo;
          enableXWayland = config.programs.hyprland.xwayland.enable;
          withSystemd = true;
          wrapRuntimeDeps = true;
        }
      );
      portalPackage = pkgs.xdg-desktop-portal-hyprland;

      withUWSM = true;
      xwayland.enable = false;
    };

    xwayland.enable = config.programs.hyprland.xwayland.enable;

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

      blesh.enable = true;

      enableLsColors = true;

      undistractMe.enable = false; # Disabled due to Misbehavior

      # shellAliases = { };

      # loginShellInit = '''';

      # shellInit = '''';

      interactiveShellInit = ''
        PROMPT_COMMAND="history -a"
      '';

      # promptInit = '''';

      # logout = '''';
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

        add_newline = false;
      };
    };

    nix-ld = {
      enable = true;
      package = pkgs.nix-ld;

      libraries =
        options.programs.nix-ld.libraries.default
        ++ (with pkgs; [
          glib.out
          libsecret
          llvmPackages.stdenv.cc.cc.lib
          sqlite
          stdenv.cc
          stdenv.cc.cc.lib
        ]);
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
        pkgs.gnupg1compat.override {
          gnupg = (
            pkgs.gnupg24.override {
              enableMinimal = false;
              guiSupport = true;
              withPcsc = true;
              withTpm2Tss = true;
            }
          );
        }
      );

      dirmngr.enable = true;

      agent = {
        enable = true;

        enableBrowserSocket = true;
        enableExtraSocket = true;

        enableSSHSupport = true;

        pinentryPackage = (
          pkgs.pinentry-qt.override {
            withLibsecret = true;
          }
        );
      };
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
    };

    dconf = {
      enable = true;

      profiles.user.databases = [
        {
          lockAll = false;

          settings = {
            "org/gnome/desktop/interface" = {
              gtk-enable-primary-paste = true;
              monospace-font-name = "${fontPreferences.name.monospace} ${pkgs.lib.toString fontPreferences.size}";
            };

            "org/gnome/desktop/privacy" = {
              remember-recent-files = false;
            };

            "org/gnome/desktop/sound" = {
              theme-name = "ocean";
            };

            "org/gnome/desktop/wm/preferences" = {
              button-layout = "appmenu:minimize,maximize,close";
            };

            "org/gtk/settings/file-chooser" = {
              show-hidden = true;
              sort-directories-first = true;
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
          };
        }
      ];
    };

    waybar = {
      enable = !config.home-manager.users.normal.programs.waybar.enable;
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

    seahorse.enable = true;

    partition-manager = {
      enable = true;
    };

    k3b.enable = true;

    nm-applet = {
      enable = true;
      package = pkgs.networkmanagerapplet;

      indicator = true;
    };

    system-config-printer.enable = true;

    virt-manager = {
      enable = true;
      package = (
        pkgs.virt-manager.override {
          spiceSupport = true;
        }
      );
    };

    ghidra = {
      enable = true;
      package = pkgs.ghidra;
      gdb = true;
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
        obs-multi-rtmp
        obs-mute-filter
        obs-pipewire-audio-capture
        obs-scale-to-sound
        obs-source-clone
        obs-source-record
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

      startAgent = !config.programs.gnupg.agent.enable;
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
  };

  fonts = {
    enableDefaultPackages = false;
    enableGhostscriptFonts = false;
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
          fontPreferences.name.monospace
        ];

        sansSerif = [
          fontPreferences.name.sansSerif
        ];

        serif = [
          fontPreferences.name.serif
        ];

        emoji = [
          fontPreferences.name.emoji
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
    shells = [
      config.home-manager.users.normal.programs.bash.package
    ];

    enableAllTerminfo = true;

    homeBinInPath = true;
    localBinInPath = true;

    stub-ld.enable = true;

    systemPackages =
      with pkgs;
      [
        # dart # flutter adds the compatible version
        # gnome-nettool # TODO: Find Alternative
        # lyto # FIXME: Build Failure
        # metadata # FIXME: Build Failure
        # reiser4progs # Marked as Broken
        # soundconverter # FIXME: Build Failure
        aapt
        acl
        acpica-tools
        acpidump-all
        act
        actionlint
        addlicense
        aegisub
        aeskeyfind
        aide
        aircrack-ng
        alac
        alsa-plugins
        alsa-utils
        android-backup-extractor
        android-tools
        ansilove
        apfs-fuse
        apfsprogs
        apkeep
        apkleaks
        appimageupdate-qt
        archivemount
        arduino-cli
        arduino-core
        arduino-ide
        arduino-ota
        arj
        ascii
        ascii-draw
        asciinema
        asciinema-agg
        asciiquarium-transparent
        asnmap
        audacity
        audio-sharing
        autopsy
        avbroot
        avrdude
        bada-bib
        bcachefs-tools
        binary
        bindfs
        binutils
        binwalk
        bitwarden-cli
        bitwarden-desktop
        blanket
        bleachbit
        bluez-alsa
        bluez-tools
        brave
        brightnessctl
        btfs
        btrfs-assistant
        btrfs-heatmap
        btrfs-progs
        bump
        bustle
        butt
        bytecode-viewer
        bzip3
        calligraphy
        carburetor
        cartero
        cavasik
        cdrkit
        celt
        censor
        certbot-full
        certdump
        chunkfs
        cine
        clang_22
        clang-analyzer
        clang-tools
        clapgrep
        clinfo
        cloc
        cloneit
        cmake
        codeowners
        codevis
        colorgrind
        compose2nix
        compsize
        concessio
        constrict
        coulomb
        cpio
        cramfsprogs
        crlfuzz
        cron
        crow-translate
        cryptsetup
        cscope
        ctagsWrapped
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
        darling-dmg
        davfs2
        dbeaver-bin # Disabling Theming Allows to Use GTK Theme
        dconf-editor
        dconf2nix
        ddrescue
        ddrescueview
        dduper
        delineate
        desktop-file-utils
        diffoci
        dig
        dippi
        dislocker
        disorderfs
        dive
        djvulibre
        dmg2img
        dmidecode
        dnsrecon
        door-knocker
        dosfstools
        dot2tex
        dpkg
        dtui
        dvb-apps
        e2fsprogs
        ebook2cw
        efibootmgr
        efivar
        egypt
        electron-mail
        elf-dissector
        eloquent
        emblem
        enumerepo
        envfs
        erofs-utils
        esptool
        etherape
        evtest-qt
        exfatprogs
        exhibit
        exiftool
        extract-dtb
        f2fs-tools
        fastlane
        fdk_aac
        fdroidcl
        fdt-viewer
        fdupes
        ffmpegthumbnailer
        ffpb
        fh
        field-monitor
        file
        fileinfo
        filen-cli
        filen-desktop
        findutils
        flake-checker
        flare-floss
        flawz
        flightgear
        flutter
        foliate
        font-manager
        fontfor
        fontforge-gtk
        fork-cleaner
        freac
        freecad
        freerouting
        fritzing
        fuse-overlayfs
        fuse3
        fwupd-efi
        gamepad-mirror
        gawd
        gawk
        gcc
        gcr_4
        gdb
        gearlever
        genealogos-cli
        gerbolyze
        gh
        gh-contribs
        gh-skyline # Generates STL File
        gh2md
        ghatm
        ghrepo-stats
        gimp-with-plugins
        gist
        git-big-picture
        git-filter-repo
        git-open
        git-repo
        github-backup
        github-changelog-generator
        github-desktop
        github-distributed-owners
        gitlogue
        glib
        gnome-firmware
        gnome-frog
        gnome-multi-writer
        gnugrep
        gnumake
        gnused
        gnutar
        go2tv
        google-lighthouse
        gource
        gphoto2fs
        gpredict
        gpu-viewer
        graphviz
        greaseweazle
        groovy
        gtk-frdp
        gtk-vnc
        gtkhash
        guestfs-tools
        gzip
        halftone
        hashes
        hdparm
        heaptrack
        helvum
        hfsprogs
        hfsutils
        hieroglyphic
        horizon-eda
        host
        hstsparser
        httpdirfs
        hw-probe
        hydra-check
        hyprgraphics
        hyprland-protocols
        hyprland-qt-support
        hyprland-qtutils
        hyprmag
        hyprpicker
        hyprshot
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
        inetutils
        inkcut
        inkscape-with-extensions
        inotify-tools
        interception-tools
        iplookup-gtk
        jfsutils
        jmol
        jq
        jstest-gtk
        jxrlib
        karlender
        kdiff3
        kernel-hardening-checker
        kernelshark
        kgeotag
        killall
        kind
        kmod
        kotlin
        krapslog
        krename
        krita
        krita-plugin-gmic
        kubectl
        kubernetes-controller-tools
        kubescape
        kubeshark
        labplot
        lenspect
        letterpress
        lha
        libaom
        libarchive
        libde265
        libfreeaptx
        libhsts
        libilbc
        libimobiledevice
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
        livecaptions
        lld_22
        llmfit
        llvm_22
        logtop
        lorem
        lsb-release
        lshw
        lsof
        lsscsi
        luminance
        lvm2
        lynis
        lyx
        lzham
        macchanger
        mailcap
        mapscii
        mdns-scanner
        megacmd
        mergerfs
        mermaid-cli
        mesa-demos
        meshlab
        metadata-cleaner
        metronome
        mfcuk
        mfoc
        millisecond
        minikube
        mixxx
        mlocate
        monkeys-audio
        morphosis
        mousam
        mp3fs
        mslicer
        mt-st
        mtools
        mysqltuner
        nethogs
        netpeek
        newelle
        newsflash
        nilfs-utils
        ninja
        nix-diff
        nix-forecast
        nix-health
        nix-info
        nix-query-tree-viewer
        nixd
        nixfmt
        nixmate
        nixoscope
        nixpkgs-reviewFull
        nmap
        noaa-apt
        nocturne
        ntfs2btrfs
        ntfs3g
        ntfsprogs-plus
        numactl
        numatop
        nurl
        nvme-cli
        nwg-bar
        nwg-drawer
        obexftp
        oha
        okteta
        onionshare-gui
        openafs
        openai-whisper
        openapv
        opencore-amr
        openh264
        openjpeg
        openobex
        openpgp-card-tools
        openssl
        orbvis
        otree
        overskride
        packet
        paleta
        pana
        paper-clip
        parallel-full
        parted
        pbzx
        pciutils
        pdfarranger
        pe-bear
        pev
        pg_top
        pgbadger
        pgpdump
        pgread
        picard
        picard-tools
        pkg-config
        platformio
        play
        playerctl
        podman-compose
        pods
        poop # POOP = Performance Optimizer Observation Platform
        powershell
        prettier
        printrun # Printerface, Pronsole
        procps
        profile-cleaner
        progress
        protocol
        proton-pass
        proton-pass-cli
        proton-vpn
        proton-vpn-cli
        protonmail-export
        protonup-qt
        ps
        psmisc
        pwvucontrol
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
        rt-tests
        rtcqs # From config.nixpkgs.overlays
        rtl-sdr-librtlsdr
        rubyPackages.cocoapods
        runme
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
        sequoia-sq
        share-preview
        shellcheck
        shellclear
        sherlock
        shfmt
        shortwave
        simple-mtpfs
        sipvicious
        sleuthkit
        sloc
        smag
        smartmontools
        sof-tools
        songrec
        sourcegit
        sox
        spectre-meltdown-checker
        speedtest
        spytrap-adb
        squashfuse
        srain
        sshfs
        sshfs-fuse
        sslscan
        standardnotes
        stdenv.cc.libc.out # Includes Locales
        steam-run-free
        stellarium
        stenc
        strace
        strace-analyzer
        streamlit
        subfinder
        svt-av1
        switcheroo
        syft
        symlinks
        tauno-monitor
        telegram-desktop
        telegraph
        teleprompter
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
        udftools
        uefi-firmware-parser
        ugit
        unar
        unarc
        undollar
        unhide
        unhide-gui
        uni2ascii
        unionfs-fuse
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
        video2x
        virt-v2v
        vorbis-tools
        vscodium
        vulnix
        wafw00f
        wavemon
        wayback_machine_downloader
        wayback-machine-archiver
        waycheck
        waydroid-helper
        wayland-scanner
        wayland-utils
        waylevel
        wayscriber
        webcamize
        webfont-bundler
        websocat
        wev
        whatfiles
        which
        whois
        whosthere
        wildcard
        windowtolayer
        wl-clipboard
        wvkbd # wvkbd-mobintl
        xar
        xdg-user-dirs
        xdg-user-dirs-gtk
        xdg-utils
        xeol
        xfsdump
        xfsprogs
        xfstests
        xhost
        xoscope
        xvidcore
        xz
        yara-x
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

        (writeShellScriptBin "cpu-x" ''
          exec sudo -E ${cpu-x}/bin/cpu-x "$@"
        '') # With config.security.sudo.extraRules

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

        (guvcview.override {
          pulseaudioSupport = true;
          useQt = false;
          useGtk = true;
        })

        (writeShellScriptBin "hardinfo2" ''
          exec sudo -E ${hardinfo2}/bin/hardinfo2 "$@"
        '') # With config.security.sudo.extraRules

        (pkgs.symlinkJoin {
          name = "krusader-with-konsole";
          paths = with pkgs; [
            krusader
          ];

          buildInputs = with pkgs; [
            makeWrapper
          ];
          postBuild = ''
            wrapProgram $out/bin/krusader \
              --prefix PATH : ${
                pkgs.lib.makeBinPath [
                  pkgs.kdePackages.konsole
                ]
              }
          '';
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

        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })

        config.hardware.firmware
        config.home-manager.users.normal.programs.dircolors.package # Overriden coreutils-full
        config.home-manager.users.normal.services.udiskie.package
        config.programs.gnupg.agent.pinentryPackage
        config.programs.nix-index.package
        config.programs.nm-applet.package # Also Provides nm-connection-editor
        config.services.phpfpm.phpPackage
      ]

      ++ pkgs.lib.optionals config.nixpkgs.config.allowUnfree [
        androidComposition.androidsdk # Custom Composition
        megasync # OSS
        rar
        unrar

        (ventoy-full-gtk.override {
          withExt4 = true;
          withNtfs = true;
          withXfs = true;
        })
      ]

      ++ config.boot.extraModulePackages
      ++ config.fonts.packages
      ++ config.hardware.graphics.extraPackages
      ++ config.hardware.graphics.extraPackages32
      ++ config.hardware.sane.extraBackends
      ++ config.home-manager.users.normal.programs.brave.nativeMessagingHosts
      ++ config.home-manager.users.normal.programs.lutris.extraPackages
      ++ config.i18n.inputMethod.fcitx5.addons
      ++ config.networking.networkmanager.plugins
      ++ config.programs.bat.extraPackages
      ++ config.programs.nix-ld.libraries
      ++ config.programs.obs-studio.plugins
      ++ config.services.pipewire.extraLv2Packages
      ++ config.services.printing.drivers
      ++ config.services.udev.packages
      ++ config.virtualisation.libvirtd.qemu.vhostUserPackages
      ++ config.virtualisation.podman.extraRuntimes
      ++ config.xdg.portal.configPackages
      ++ config.xdg.portal.extraPortals

      ++ (with ghidra-extensions; [
        findcrypt
        ghidra-delinker-extension
        ghidra-firmware-utils
        gnudisassembler
        kaiju
        lightkeeper
        machinelearning
        ret-sync
      ])

      ++ (with gst_all_1; [
        (gst-libav.override {
          enableDocumentation = config.documentation.enable;
        })

        (gst-plugins-bad.override {
          ajaSupport = true;
          bluezSupport = true;
          enableDocumentation = config.documentation.enable;
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
          enableDocumentation = config.documentation.enable;
          enableWayland = true;
        })

        (gst-plugins-good.override {
          enableDocumentation = config.documentation.enable;
          enableJack = true;
          enableWayland = true;
          gtkSupport = true;
          qt6Support = true;
        })

        (gst-plugins-ugly.override {
          enableDocumentation = config.documentation.enable;
          enableGplPlugins = true;
        })

        (gstreamer.override {
          enableDocumentation = config.documentation.enable;
        })
      ])

      ++ (with kdePackages; [
        ark
        audiocd-kio
        ffmpegthumbs
        filelight
        gwenview
        kalgebra
        kalzium
        kcachegrind
        kcharselect
        kclock
        kcolorchooser
        kdegraphics-mobipocket
        kdegraphics-thumbnailers
        kdenlive
        kfind
        kget
        kimageformats
        kio
        kio-admin
        kio-extras
        kio-extras-kf5
        kio-fuse
        kio-zeroconf
        kjournald
        kleopatra
        kmahjongg
        kmousetool
        kmouth
        kontrast
        krdp
        krfb
        kruler
        kshisen
        kubrick
        marble
        ocean-sound-theme
        okular
        poppler
        qrca
        skanpage
        step
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

    wordlist.enable = false;

    pathsToLink = [
      "/share/applications"
      "/share/i18n"
      "/share/xdg-desktop-portal"
    ];

    # etc = { };

    variables = {
      # LD_LIBRARY_PATH = pkgs.lib.mkForce (
      #   pkgs.lib.makeLibraryPath config.programs.nix-ld.libraries + ":$LD_LIBRARY_PATH"
      # );

      GI_TYPELIB_PATH = pkgs.lib.mkForce "${pkgs.libportal}/lib/girepository-1.0:${pkgs.libportal-gtk4}/lib/girepository-1.0:GI_TYPELIB_PATH";

      CHROME_EXECUTABLE = "brave";
    }
    // pkgs.lib.optionalAttrs config.nixpkgs.config.allowUnfree {
      ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
      ANDROID_SDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk";
      ANDROID_NDK_ROOT = "${androidComposition.androidsdk}/libexec/android-sdk/ndk-bundle";
    };

    sessionVariables = {
      ADW_DISABLE_PORTAL = 1;

      NIXOS_OZONE_WL = 1;
      ELECTRON_OZONE_PLATFORM_HINT = "auto";

      XCURSOR_THEME = config.home-manager.users.normal.home.pointerCursor.name;
      XCURSOR_SIZE = config.home-manager.users.normal.home.pointerCursor.size;
    };

    shellAliases = {
      unbind_i8042_driver = "echo -n i8042 | sudo tee /sys/bus/platform/drivers/i8042/unbind >/dev/null";
      bind_i8042_driver = "echo -n i8042 | sudo tee /sys/bus/platform/drivers/i8042/bind >/dev/null";

      commands = "uwsm-app -- wezterm start --always-new-process -- bash -ic 'cmd=\$(compgen -c | sort -u | tv); [ -n \"\\$cmd\" ] && eval \"\\$cmd\"; exec bash -i'";

      clean_optimise_upgrade = "sudo nh clean all && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
      clean_repair_optimise_upgrade = "sudo nh clean all && sudo nix-store --verify --check-contents --repair && sudo nix-store --optimise && sudo nixos-rebuild switch --upgrade-all --refresh --install-bootloader";
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
          "org.wezfurlong.wezterm.desktop"
        ];
      };
    };

    portal = {
      enable = true;
      extraPortals = [
        config.home-manager.users.normal.services.gnome-keyring.package
        pkgs.xdg-desktop-portal-gtk
      ]; # config.programs.hyprland.portalPackage adds xdg-desktop-portal-hyprland to it.

      xdgOpenUsePortal = true;
    };

    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      # https://www.iana.org/assignments/media-types/media-types.xhtml
      defaultApplications = {
        "inode/directory" = "org.kde.krusader.desktop";

        "text/1d-interleaved-parityfec" = "codium.desktop";
        "text/cache-manifest" = "codium.desktop";
        "text/calendar" = "codium.desktop";
        "text/cql" = "codium.desktop";
        "text/cql-expression" = "codium.desktop";
        "text/cql-identifier" = "codium.desktop";
        "text/css" = "codium.desktop";
        "text/csv" = "codium.desktop";
        "text/csv-schema" = "codium.desktop";
        "text/directory" = "codium.desktop";
        "text/dns" = "codium.desktop";
        "text/ecmascript" = "codium.desktop";
        "text/encaprtp" = "codium.desktop";
        "text/enriched" = "codium.desktop";
        "text/fhirpath" = "codium.desktop";
        "text/flexfec" = "codium.desktop";
        "text/fwdred" = "codium.desktop";
        "text/gff3" = "codium.desktop";
        "text/grammar-ref-list" = "codium.desktop";
        "text/hl7v2" = "codium.desktop";
        "text/html" = "codium.desktop";
        "text/javascript" = "codium.desktop";
        "text/jcr-cnd" = "codium.desktop";
        "text/markdown" = "codium.desktop";
        "text/mizar" = "codium.desktop";
        "text/n3" = "codium.desktop";
        "text/org" = "codium.desktop";
        "text/parameters" = "codium.desktop";
        "text/parityfec" = "codium.desktop";
        "text/plain" = "codium.desktop";
        "text/provenance-notation" = "codium.desktop";
        "text/prs.fallenstein.rst" = "codium.desktop";
        "text/prs.lines.tag" = "codium.desktop";
        "text/prs.prop.logic" = "codium.desktop";
        "text/prs.texi" = "codium.desktop";
        "text/raptorfec" = "codium.desktop";
        "text/RED" = "codium.desktop";
        "text/rfc822-headers" = "codium.desktop";
        "text/richtext" = "codium.desktop";
        "text/rtf" = "codium.desktop";
        "text/rtp-enc-aescm128" = "codium.desktop";
        "text/rtploopback" = "codium.desktop";
        "text/rtx" = "codium.desktop";
        "text/SGML" = "codium.desktop";
        "text/shaclc" = "codium.desktop";
        "text/shex" = "codium.desktop";
        "text/spdx" = "codium.desktop";
        "text/strings" = "codium.desktop";
        "text/t140" = "codium.desktop";
        "text/tab-separated-values" = "codium.desktop";
        "text/troff" = "codium.desktop";
        "text/turtle" = "codium.desktop";
        "text/ulpfec" = "codium.desktop";
        "text/uri-list" = "codium.desktop";
        "text/vcard" = "codium.desktop";
        "text/vnd.a" = "codium.desktop";
        "text/vnd.abc" = "codium.desktop";
        "text/vnd.ascii-art" = "codium.desktop";
        "text/vnd.curl" = "codium.desktop";
        "text/vnd.debian.copyright" = "codium.desktop";
        "text/vnd.DMClientScript" = "codium.desktop";
        "text/vnd.dvb.subtitle" = "codium.desktop";
        "text/vnd.esmertec.theme-descriptor" = "codium.desktop";
        "text/vnd.exchangeable" = "codium.desktop";
        "text/vnd.familysearch.gedcom" = "codium.desktop";
        "text/vnd.ficlab.flt" = "codium.desktop";
        "text/vnd.fly" = "codium.desktop";
        "text/vnd.fmi.flexstor" = "codium.desktop";
        "text/vnd.gml" = "codium.desktop";
        "text/vnd.graphviz" = "codium.desktop";
        "text/vnd.hans" = "codium.desktop";
        "text/vnd.hgl" = "codium.desktop";
        "text/vnd.in3d.3dml" = "codium.desktop";
        "text/vnd.in3d.spot" = "codium.desktop";
        "text/vnd.IPTC.NewsML" = "codium.desktop";
        "text/vnd.IPTC.NITF" = "codium.desktop";
        "text/vnd.latex-z" = "codium.desktop";
        "text/vnd.motorola.reflex" = "codium.desktop";
        "text/vnd.ms-mediapackage" = "codium.desktop";
        "text/vnd.net2phone.commcenter.command" = "codium.desktop";
        "text/vnd.radisys.msml-basic-layout" = "codium.desktop";
        "text/vnd.senx.warpscript" = "codium.desktop";
        "text/vnd.si.uricatalogue" = "codium.desktop";
        "text/vnd.sosi" = "codium.desktop";
        "text/vnd.sun.j2me.app-descriptor" = "codium.desktop";
        "text/vnd.trolltech.linguist" = "codium.desktop";
        "text/vnd.typst" = "codium.desktop";
        "text/vnd.vcf" = "codium.desktop";
        "text/vnd.wap.si" = "codium.desktop";
        "text/vnd.wap.sl" = "codium.desktop";
        "text/vnd.wap.wml" = "codium.desktop";
        "text/vnd.wap.wmlscript" = "codium.desktop";
        "text/vnd.zoo.kcl" = "codium.desktop";
        "text/vtt" = "codium.desktop";
        "text/wgsl" = "codium.desktop";
        "text/xml" = "codium.desktop";
        "text/xml-external-parsed-entity" = "codium.desktop";

        "image/aces" = "org.kde.gwenview.desktop";
        "image/apng" = "org.kde.gwenview.desktop";
        "image/avci" = "org.kde.gwenview.desktop";
        "image/avcs" = "org.kde.gwenview.desktop";
        "image/avif" = "org.kde.gwenview.desktop";
        "image/bmp" = "org.kde.gwenview.desktop";
        "image/cgm" = "org.kde.gwenview.desktop";
        "image/dicom-rle" = "org.kde.gwenview.desktop";
        "image/dpx" = "org.kde.gwenview.desktop";
        "image/emf" = "org.kde.gwenview.desktop";
        "image/fits" = "org.kde.gwenview.desktop";
        "image/g3fax" = "org.kde.gwenview.desktop";
        "image/gif" = "org.kde.gwenview.desktop";
        "image/heic-sequence" = "org.kde.gwenview.desktop";
        "image/heic" = "org.kde.gwenview.desktop";
        "image/heif-sequence" = "org.kde.gwenview.desktop";
        "image/heif" = "org.kde.gwenview.desktop";
        "image/hej2k" = "org.kde.gwenview.desktop";
        "image/hsj2" = "org.kde.gwenview.desktop";
        "image/ief" = "org.kde.gwenview.desktop";
        "image/j2c" = "org.kde.gwenview.desktop";
        "image/jaii" = "org.kde.gwenview.desktop";
        "image/jais" = "org.kde.gwenview.desktop";
        "image/jls" = "org.kde.gwenview.desktop";
        "image/jp2" = "org.kde.gwenview.desktop";
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/jph" = "org.kde.gwenview.desktop";
        "image/jphc" = "org.kde.gwenview.desktop";
        "image/jpm" = "org.kde.gwenview.desktop";
        "image/jpx" = "org.kde.gwenview.desktop";
        "image/jxl" = "org.kde.gwenview.desktop";
        "image/jxr" = "org.kde.gwenview.desktop";
        "image/jxrA" = "org.kde.gwenview.desktop";
        "image/jxrS" = "org.kde.gwenview.desktop";
        "image/jxs" = "org.kde.gwenview.desktop";
        "image/jxsc" = "org.kde.gwenview.desktop";
        "image/jxsi" = "org.kde.gwenview.desktop";
        "image/jxss" = "org.kde.gwenview.desktop";
        "image/ktx" = "org.kde.gwenview.desktop";
        "image/ktx2" = "org.kde.gwenview.desktop";
        "image/naplps" = "org.kde.gwenview.desktop";
        "image/png" = "org.kde.gwenview.desktop";
        "image/prs.btif" = "org.kde.gwenview.desktop";
        "image/prs.pti" = "org.kde.gwenview.desktop";
        "image/pwg-raster" = "org.kde.gwenview.desktop";
        "image/svg+xml" = "org.kde.gwenview.desktop";
        "image/t38" = "org.kde.gwenview.desktop";
        "image/tiff-fx" = "org.kde.gwenview.desktop";
        "image/tiff" = "org.kde.gwenview.desktop";
        "image/vnd.adobe.photoshop" = "org.kde.gwenview.desktop";
        "image/vnd.airzip.accelerator.azv" = "org.kde.gwenview.desktop";
        "image/vnd.blockfact.facti" = "org.kde.gwenview.desktop";
        "image/vnd.clip" = "org.kde.gwenview.desktop";
        "image/vnd.cns.inf2" = "org.kde.gwenview.desktop";
        "image/vnd.dece.graphic" = "org.kde.gwenview.desktop";
        "image/vnd.djvu" = "org.kde.gwenview.desktop";
        "image/vnd.dvb.subtitle" = "org.kde.gwenview.desktop";
        "image/vnd.dwg" = "org.kde.gwenview.desktop";
        "image/vnd.dxf" = "org.kde.gwenview.desktop";
        "image/vnd.fastbidsheet" = "org.kde.gwenview.desktop";
        "image/vnd.fpx" = "org.kde.gwenview.desktop";
        "image/vnd.fst" = "org.kde.gwenview.desktop";
        "image/vnd.fujixerox.edmics-mmr" = "org.kde.gwenview.desktop";
        "image/vnd.fujixerox.edmics-rlc" = "org.kde.gwenview.desktop";
        "image/vnd.globalgraphics.pgb" = "org.kde.gwenview.desktop";
        "image/vnd.microsoft.icon" = "org.kde.gwenview.desktop";
        "image/vnd.mix" = "org.kde.gwenview.desktop";
        "image/vnd.mozilla.apng" = "org.kde.gwenview.desktop";
        "image/vnd.ms-modi" = "org.kde.gwenview.desktop";
        "image/vnd.net-fpx" = "org.kde.gwenview.desktop";
        "image/vnd.pco.b16" = "org.kde.gwenview.desktop";
        "image/vnd.radiance" = "org.kde.gwenview.desktop";
        "image/vnd.sealed.png" = "org.kde.gwenview.desktop";
        "image/vnd.sealedmedia.softseal.gif" = "org.kde.gwenview.desktop";
        "image/vnd.sealedmedia.softseal.jpg" = "org.kde.gwenview.desktop";
        "image/vnd.svf" = "org.kde.gwenview.desktop";
        "image/vnd.tencent.tap" = "org.kde.gwenview.desktop";
        "image/vnd.valve.source.texture" = "org.kde.gwenview.desktop";
        "image/vnd.wap.wbmp" = "org.kde.gwenview.desktop";
        "image/vnd.xiff" = "org.kde.gwenview.desktop";
        "image/vnd.zbrush.pcx" = "org.kde.gwenview.desktop";
        "image/webp" = "org.kde.gwenview.desktop";
        "image/wmf" = "org.kde.gwenview.desktop";
        "image/x-emf" = "org.kde.gwenview.desktop";
        "image/x-wmf" = "org.kde.gwenview.desktop";

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

        "video/1d-interleaved-parityfec" = "io.github.diegopvlk.Cine.desktop";
        "video/3gpp-tt" = "io.github.diegopvlk.Cine.desktop";
        "video/3gpp" = "io.github.diegopvlk.Cine.desktop";
        "video/3gpp2" = "io.github.diegopvlk.Cine.desktop";
        "video/AV1" = "io.github.diegopvlk.Cine.desktop";
        "video/BMPEG" = "io.github.diegopvlk.Cine.desktop";
        "video/BT656" = "io.github.diegopvlk.Cine.desktop";
        "video/CelB" = "io.github.diegopvlk.Cine.desktop";
        "video/DV" = "io.github.diegopvlk.Cine.desktop";
        "video/encaprtp" = "io.github.diegopvlk.Cine.desktop";
        "video/evc" = "io.github.diegopvlk.Cine.desktop";
        "video/FFV1" = "io.github.diegopvlk.Cine.desktop";
        "video/flexfec" = "io.github.diegopvlk.Cine.desktop";
        "video/H261" = "io.github.diegopvlk.Cine.desktop";
        "video/H263-1998" = "io.github.diegopvlk.Cine.desktop";
        "video/H263-2000" = "io.github.diegopvlk.Cine.desktop";
        "video/H263" = "io.github.diegopvlk.Cine.desktop";
        "video/H264-RCDO" = "io.github.diegopvlk.Cine.desktop";
        "video/H264-SVC" = "io.github.diegopvlk.Cine.desktop";
        "video/H264" = "io.github.diegopvlk.Cine.desktop";
        "video/H265" = "io.github.diegopvlk.Cine.desktop";
        "video/H266" = "io.github.diegopvlk.Cine.desktop";
        "video/iso.segment" = "io.github.diegopvlk.Cine.desktop";
        "video/JPEG" = "io.github.diegopvlk.Cine.desktop";
        "video/jpeg2000-scl" = "io.github.diegopvlk.Cine.desktop";
        "video/jpeg2000" = "io.github.diegopvlk.Cine.desktop";
        "video/jxsv" = "io.github.diegopvlk.Cine.desktop";
        "video/lottie+json" = "io.github.diegopvlk.Cine.desktop";
        "video/matroska-3d" = "io.github.diegopvlk.Cine.desktop";
        "video/matroska" = "io.github.diegopvlk.Cine.desktop";
        "video/mj2" = "io.github.diegopvlk.Cine.desktop";
        "video/MP1S" = "io.github.diegopvlk.Cine.desktop";
        "video/MP2P" = "io.github.diegopvlk.Cine.desktop";
        "video/MP2T" = "io.github.diegopvlk.Cine.desktop";
        "video/mp4" = "io.github.diegopvlk.Cine.desktop";
        "video/MP4V-ES" = "io.github.diegopvlk.Cine.desktop";
        "video/mpeg" = "io.github.diegopvlk.Cine.desktop";
        "video/mpeg4-generic" = "io.github.diegopvlk.Cine.desktop";
        "video/MPV" = "io.github.diegopvlk.Cine.desktop";
        "video/nv" = "io.github.diegopvlk.Cine.desktop";
        "video/ogg" = "io.github.diegopvlk.Cine.desktop";
        "video/parityfec" = "io.github.diegopvlk.Cine.desktop";
        "video/pointer" = "io.github.diegopvlk.Cine.desktop";
        "video/quicktime" = "io.github.diegopvlk.Cine.desktop";
        "video/raptorfec" = "io.github.diegopvlk.Cine.desktop";
        "video/raw" = "io.github.diegopvlk.Cine.desktop";
        "video/rtp-enc-aescm128" = "io.github.diegopvlk.Cine.desktop";
        "video/rtploopback" = "io.github.diegopvlk.Cine.desktop";
        "video/rtx" = "io.github.diegopvlk.Cine.desktop";
        "video/scip" = "io.github.diegopvlk.Cine.desktop";
        "video/smpte291" = "io.github.diegopvlk.Cine.desktop";
        "video/SMPTE292M" = "io.github.diegopvlk.Cine.desktop";
        "video/ulpfec" = "io.github.diegopvlk.Cine.desktop";
        "video/vc1" = "io.github.diegopvlk.Cine.desktop";
        "video/vc2" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.blockfact.factv" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.CCTV" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dece.hd" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dece.mobile" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dece.mp4" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dece.pd" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dece.sd" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dece.video" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.directv.mpeg-tts" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.directv.mpeg" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dlna.mpeg-tts" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.dvb.file" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.fvt" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.hns.video" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.iptvforum.1dparityfec-1010" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.iptvforum.1dparityfec-2005" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.iptvforum.2dparityfec-1010" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.iptvforum.2dparityfec-2005" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.iptvforum.ttsavc" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.iptvforum.ttsmpeg2" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.motorola.video" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.motorola.videop" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.mpegurl" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.ms-playready.media.pyv" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.nokia.interleaved-multimedia" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.nokia.mp4vr" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.nokia.videovoip" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.objectvideo" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.planar" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.radgamettools.bink" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.radgamettools.smacker" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.sealed.mpeg1" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.sealed.mpeg4" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.sealed.swf" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.sealedmedia.softseal.mov" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.uvvu.mp4" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.vivo" = "io.github.diegopvlk.Cine.desktop";
        "video/vnd.youtube.yt" = "io.github.diegopvlk.Cine.desktop";
        "video/VP8" = "io.github.diegopvlk.Cine.desktop";
        "video/VP9" = "io.github.diegopvlk.Cine.desktop";
        "video/x-matroska" = "io.github.diegopvlk.Cine.desktop"; # https://mime.wcode.net/mkv

        "application/vnd.oasis.opendocument.text" = "onlyoffice-desktopeditors.desktop"; # .odt
        "application/msword" = "onlyoffice-desktopeditors.desktop"; # .doc
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document" =
          "onlyoffice-desktopeditors.desktop"; # .docx
        "application/vnd.openxmlformats-officedocument.wordprocessingml.template" =
          "onlyoffice-desktopeditors.desktop"; # .dotx

        "application/vnd.oasis.opendocument.spreadsheet" = "onlyoffice-desktopeditors.desktop"; # .ods
        "application/vnd.ms-excel" = "onlyoffice-desktopeditors.desktop"; # .xls
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" =
          "onlyoffice-desktopeditors.desktop"; # .xlsx
        "application/vnd.openxmlformats-officedocument.spreadsheetml.template" =
          "onlyoffice-desktopeditors.desktop"; # .xltx

        "application/vnd.oasis.opendocument.presentation" = "onlyoffice-desktopeditors.desktop"; # .odp
        "application/vnd.ms-powerpoint" = "onlyoffice-desktopeditors.desktop"; # .ppt
        "application/vnd.openxmlformats-officedocument.presentationml.presentation" =
          "onlyoffice-desktopeditors.desktop"; # .pptx
        "application/vnd.openxmlformats-officedocument.presentationml.template" =
          "onlyoffice-desktopeditors.desktop"; # .potx

        "application/pdf" = "org.kde.okular.desktop";

        "model/stl" = "io.github.nokse22.Exhibit.desktop";

        "application/gzip" = "org.kde.ark.desktop";
        "application/vnd.rar" = "org.kde.ark.desktop";
        "application/x-7z-compressed" = "org.kde.ark.desktop";
        "application/x-arj" = "org.kde.ark.desktop";
        "application/x-bzip2" = "org.kde.ark.desktop";
        "application/x-gtar" = "org.kde.ark.desktop";
        "application/x-rar-compressed " = "org.kde.ark.desktop"; # More Common Than "application/vnd.rar"
        "application/x-tar" = "org.kde.ark.desktop";
        "application/zip" = "org.kde.ark.desktop";

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

        "x-scheme-handler/mailto" = "electron-mail.desktop";
      };
    };
  };

  gtk.iconCache.enable = true;

  qt = {
    enable = true;

    platformTheme = "qt5ct"; # Both qt6ct and qt5ct
    style = "kvantum";
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

    cursors = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;
    };

    gtk.icon.enable = false; # Done Manually Instead

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

    defaultUserShell = config.home-manager.users.normal.programs.bash.package;

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
          "audio"
          "avahi"
          "cdrom"
          "dialout"
          "disk"
          "floppy"
          "fwupd-refresh"
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
          };

          preferXdgDirectories = true;

          pointerCursor = {
            enable = true;

            name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-cursors";
            # package = config.catppuccin.sources.cursors."${config.catppuccin.flavor}${pkgs.lib.toSentenceCase config.catppuccin.accent}"; # Already Defined by Catppuccin
            size = 20;

            gtk = {
              enable = true;
              size = config.home-manager.users.normal.home.pointerCursor.size;
            };

            x11.enable = config.programs.hyprland.xwayland.enable;

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

          enableDebugInfo = config.environment.enableDebugInfo;

          stateVersion = config.system.stateVersion;
        };

        i18n = {
          inputMethod = {
            enable = config.i18n.inputMethod.enable;

            type = config.i18n.inputMethod.type;
            fcitx5 = {
              addons = config.i18n.inputMethod.fcitx5.addons;
              waylandFrontend = config.i18n.inputMethod.fcitx5.waylandFrontend;

              systemd.enable = true;
              ignoreUserConfig = config.i18n.inputMethod.fcitx5.ignoreUserConfig;
            };
          };
        };

        fonts.fontconfig = {
          enable = config.fonts.fontconfig.enable;

          defaultFonts = config.fonts.fontconfig.defaultFonts;

          antialiasing = config.fonts.fontconfig.antialias;
          hinting = pkgs.lib.optionals config.fonts.fontconfig.hinting.enable config.fonts.fontconfig.hinting.style;
          subpixelRendering = config.fonts.fontconfig.subpixel.rgba;
        };

        xsession.enable = config.services.xserver.enable;

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

          xwayland.enable = config.programs.hyprland.xwayland.enable;

          configType = "lua";
          sourceFirst = true;

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
                (pkgs.lib.generators.mkLuaInline ''
                  function()
                    hl.exec_cmd("dbus-update-activation-environment --systemd --all") -- Fixes the Soteria Service Not Starting

                    hl.exec_cmd("uwsm-app -- cursor-clip --daemon")
                  end
                '')
              ];
            };

            bind = [
              {
                _args = [
                  "XF86MonBrightnessUp"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl set 1%+\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86MonBrightnessDown"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl set 1%-\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }

              {
                _args = [
                  "XF86AudioRaiseVolume"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioLowerVolume"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-\")")
                  {
                    repeating = true;
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioMute"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioMicMute"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle\")")
                  {
                    locked = true;
                  }
                ];
              }

              {
                _args = [
                  "XF86AudioPlay"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl play-pause\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioPause"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl play-pause\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioStop"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl stop\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioPrev"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl previous\")")
                  {
                    locked = true;
                  }
                ];
              }
              {
                _args = [
                  "XF86AudioNext"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl next\")")
                  {
                    locked = true;
                  }
                ];
              }

              {
                _args = [
                  "SUPER + 1"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 2"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"2\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 3"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"3\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 4"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"4\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 5"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"5\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 6"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"6\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 7"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"7\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 8"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"8\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 9"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"9\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 0"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"10\"})")
                ];
              }
              {
                _args = [
                  "SUPER + mouse_down"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m+1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + mouse_up"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m-1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + S"
                  (pkgs.lib.generators.mkLuaInline " hl.dsp.workspace.toggle_special(\"magic\")")
                ];
              }

              {
                _args = [
                  "SUPER + up"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"u\"})")
                ];
              }
              {
                _args = [
                  "SUPER + right"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"r\"})")
                ];
              }
              {
                _args = [
                  "SUPER + down"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"d\"})")
                ];
              }
              {
                _args = [
                  "SUPER + left"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"l\"})")
                ];
              }

              {
                _args = [
                  "SUPER + SHIFT + 1"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 2"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"2\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 3"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"3\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 4"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"4\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 5"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"5\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 6"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"6\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 7"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"7\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 8"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"8\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 9"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"9\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 0"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"10\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + S"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"special:magic\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 1"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"1\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 2"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"2\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 3"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"3\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 4"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"4\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 5"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"5\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 6"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"6\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 7"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"7\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 8"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"8\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 9"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"9\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 0"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"10\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + S"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"special:magic\", follow=false})")
                ];
              }

              {
                _args = [
                  "SUPER + mouse:272"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.drag()")
                  {
                    mouse = true;
                  }
                ];
              } # Left Button
              {
                _args = [
                  "SUPER + mouse:273"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.resize()")
                  {
                    mouse = true;
                  }
                ];
              } # Right Button
              {
                _args = [
                  "ALT + F11"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"maximized\"})")
                ];
              }
              {
                _args = [
                  "F11"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"fullscreen\"})")
                ];
              }
              {
                _args = [
                  "SUPER + Q"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.close()")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + Q"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.kill()")
                ];
              }

              {
                _args = [
                  "SUPER + L"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-bar -p center -t 'bar.json' -s 'style.css'\")")
                ];
              }

              {
                _args = [
                  "SUPER + A"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wayscriber --no-tray --active\")")
                ];
              }
              {
                _args = [
                  "Print"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=region --clipboard-only\")")
                ];
              }
              {
                _args = [
                  "SHIFT + Print"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=window --clipboard-only\")")
                ];
              }
              {
                _args = [
                  "ALT + Print"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=region\")")
                ];
              }
              {
                _args = [
                  "SHIFT + ALT + Print"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=window\")")
                ];
              }

              {
                _args = [
                  "SUPER + SPACE"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- cursor-clip\")")
                ];
              }

              {
                _args = [
                  "SUPER + RETURN"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-drawer -ovl -closebtn none -c 8 -g ${config.home-manager.users.normal.gtk.theme.name} -i ${config.home-manager.users.normal.gtk.iconTheme.name} -pbuseicontheme -lang en -k -wm uwsm -term wezterm -fm krusader\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + RETURN"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_raw(\"bash -ic 'commands'\")") # Alias Requires Interactive Shell
                ];
              }

              {
                _args = [
                  "SUPER + T"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- wezterm start --always-new-process\")")
                ];
              }
              {
                _args = [
                  "XF86Explorer"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- krusader\")")
                ];
              }
              {
                _args = [
                  "SUPER + F"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- krusader\")")
                ];
              }
              {
                _args = [
                  "SUPER + W"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brave\")")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + W"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brave --incognito\")")
                ];
              }
              {
                _args = [
                  "XF86Mail"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- electron-mail\")")
                ];
              }
              {
                _args = [
                  "SUPER + E"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- codium\")")
                ];
              }
            ];

            config = {
              general = {
                allow_tearing = true;

                gaps_workspaces = 0;

                layout = "dwindle";

                gaps_in = builtins.floor (designFactor / 4); # 4
                gaps_out = {
                  top = builtins.floor (designFactor / 4); # 4
                  right = builtins.floor (designFactor / 4); # 4
                  bottom = builtins.floor (designFactor / 4); # 4
                  left = builtins.floor (designFactor / 4); # 4
                };

                float_gaps = builtins.floor (designFactor / 4); # 4

                border_size = 1;
                "col.inactive_border" = pkgs.lib.mkLuaInline "colors.surface1";
                "col.active_border" = pkgs.lib.mkLuaInline "colors.surface2";
                "col.nogroup_border" = pkgs.lib.mkLuaInline "colors.surface1";
                "col.nogroup_border_active" = pkgs.lib.mkLuaInline "colors.surface2";

                resize_on_border = true;
                hover_icon_on_border = true;

                no_focus_fallback = false;

                snap = {
                  enabled = true;

                  respect_gaps = true;
                  monitor_gap = builtins.floor (designFactor / 4); # 4
                  window_gap = builtins.floor (designFactor / 4); # 4

                  border_overlap = false;
                };

                modal_parent_blocking = true;

                locale = "en_US";
              };

              decoration = {
                shadow = {
                  enabled = true;

                  sharp = false;
                };

                border_part_of_window = true;
                rounding = builtins.floor (designFactor / 2); # 8
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
              };

              animations = {
                enabled = true;

                workspace_wraparound = false;
              };

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

                virtualkeyboard = {
                  release_pressed_on_close = true;
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

                font_family = fontPreferences.name.sansSerif;
              };

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

              xwayland = {
                enabled = config.programs.hyprland.xwayland.enable;
                create_abstract_socket = true;

                force_zero_scaling = true; # Sacle = 1
                use_nearest_neighbor = true;
              };

              render = {
                cm_enabled = true;
                cm_auto_hdr = 1; # 1 = Automatically switch to "cm, hdr" in fullscreen when needed.
                send_content_type = true;
                new_render_scheduling = true;
                xp_mode = false;
                commit_timing_enabled = true;
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

              ecosystem = {
                enforce_permissions = false;

                no_update_news = false;
                no_donation_nag = false;
              };

              quirks = {
                prefer_hdr = 2; # 2 = Gamescope Only
              };

              dwindle = {
                force_split = 0; # 0 = Split Follows Mouse
                use_active_for_splits = true;
                smart_split = false;
                preserve_split = true;

                smart_resizing = true;

                precise_mouse_move = true;
              };
            }; # Sorted from "General" to "Quirks" according to Wiki/Configuring/Basics/Variables.

          };

          extraConfig = ''
            pcall(require, "monitors") -- Import if available.
          ''; # nwg-displays

          xdph.settings = {
            general = {
              toplevel_dynamic_bind = true;
            };

            screencopy = {
              allow_token_by_default = true;

              force_shm = false;
              cursor_mode = 2; # 2 = Embedded Mode # Lacks Support for 4 (Metadata Mode)
              max_fps = 0; # 0 = Unlimited
            };
          }; # xdg-desktop-portal-hyprland
        };

        xdg = {
          desktopEntries = {
            cpu-x =
              let
                desktopFile = "${pkgs.cpu-x}/share/applications/io.github.thetumultuousunicornofdarkness.cpu-x.desktop";

                get =
                  key:
                  pkgs.runCommand "get_${key}_from_cpu-x_desktop_file" { } ''
                    ${pkgs.python3}/bin/python3 - << 'EOF' > $out
                    import configparser

                    parser = configparser.ConfigParser(strict=False)

                    parser.read("${desktopFile}")
                    value = parser.get("Desktop Entry", "${key}", fallback="")
                    print(value)

                    EOF
                  '';
              in
              {
                type = pkgs.lib.strings.trim (builtins.readFile (get "Type"));
                categories = pkgs.lib.splitString ";" (builtins.readFile (get "Categories"));

                name = builtins.readFile (get "Name");
                icon = builtins.readFile (get "Icon"); # Available in config.home-manager.users.normal.gtk.iconTheme
                comment = builtins.readFile (get "Comment");

                exec = builtins.readFile (get "Exec"); # Calls the same binary as the output of writeShellScriptBin in config.environment.systemPackages
                terminal = builtins.fromJSON (
                  pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "Terminal")))
                );

                settings = {
                  Keywords = builtins.readFile (get "Keywords");
                };
              }; # Addition

            hardinfo2 =
              let
                desktopFile = "${pkgs.hardinfo2}/share/applications/hardinfo2.desktop";

                get =
                  key:
                  pkgs.runCommand "get_${key}_from_hardinfo2_desktop_file" { } ''
                    ${pkgs.python3}/bin/python3 - << 'EOF' > $out
                    import configparser

                    parser = configparser.ConfigParser(strict=False)

                    parser.read("${desktopFile}")
                    value = parser.get("Desktop Entry", "${key}", fallback="")
                    print(value)

                    EOF
                  '';
              in
              {
                type = pkgs.lib.strings.trim (builtins.readFile (get "Type"));
                categories = pkgs.lib.splitString ";" (builtins.readFile (get "Categories"));

                name = builtins.readFile (get "Name");
                icon = "${pkgs.hardinfo2}/share/icons/hicolor/scalable/apps/hardinfo2.svg";
                comment = builtins.readFile (get "Comment");

                exec = builtins.readFile (get "Exec"); # Calls the same binary as the output of writeShellScriptBin in config.environment.systemPackages
                terminal = builtins.fromJSON (
                  pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "Terminal")))
                );
                startupNotify = builtins.fromJSON (
                  pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "StartupNotify")))
                );

                settings = {
                  Keywords = builtins.readFile (get "Keywords");
                };
              }; # Addition

            raindropio =
              let
                desktopFile = "${pkgs.raindropioDesktopFile}";

                get =
                  key:
                  pkgs.runCommand "get_${key}_from_raindropio_desktop_file" { } ''
                    ${pkgs.python3}/bin/python3 - << 'EOF' > $out
                    import configparser

                    parser = configparser.ConfigParser(strict=False)

                    parser.read("${desktopFile}")
                    value = parser.get("Desktop Entry", "${key}", fallback="")
                    print(value)

                    EOF
                  '';
              in
              {
                type = pkgs.lib.strings.trim (builtins.readFile (get "Type"));
                categories = pkgs.lib.splitString ";" (builtins.readFile (get "Categories"));

                name = builtins.readFile (get "Name");
                icon = builtins.readFile (get "Icon"); # Available in config.home-manager.users.normal.gtk.iconTheme
                comment = builtins.readFile (get "Comment");

                mimeType = pkgs.lib.filter (value: value != "") (
                  pkgs.lib.splitString ";" (pkgs.lib.strings.trim (builtins.readFile (get "MimeType")))
                );
                exec = "raindropio";
                terminal = builtins.fromJSON (
                  pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "Terminal")))
                );

                settings = {
                  X-AppImage-Version = builtins.readFile (get "X-AppImage-Version");
                  StartupWMClass = builtins.readFile (get "StartupWMClass");
                };
              }; # Addition
          };

          portal = {
            enable = config.xdg.portal.enable;
            extraPortals = config.xdg.portal.extraPortals;

            xdgOpenUsePortal = config.xdg.portal.xdgOpenUsePortal;
          };

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
            "mimeapps.list" = {
              force = true;
            };

            # "qt6ct/colors/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf" = {
            #   enable = true;

            #   source = "${pkgs.catppuccin-qt5ct}/share/qt6ct/colors/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";

            #   target = "qt6ct/colors/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";
            #   executable = null;
            # };

            # "qt5ct/colors/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf" = {
            #   enable = true;

            #   source = "${pkgs.catppuccin-qt5ct}/share/qt5ct/colors/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";

            #   target = "qt5ct/colors/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";
            #   executable = null;
            # };

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
                  border-radius: ${pkgs.lib.toString (builtins.floor (designFactor / 2))}px;
                }

                #bar {
                  margin: ${pkgs.lib.toString (builtins.floor (designFactor * 2))}px;
                  font-size: ${pkgs.lib.toString (builtins.floor designFactor)}px;
                  font-family: ${fontPreferences.name.sansSerif};
                }

                button,
                image {
                  box-shadow: none;
                  border-style: none;
                  background: none;
                  color: rgb(205, 214, 244);
                }

                button {
                  margin: ${pkgs.lib.toString (builtins.floor (designFactor / 4))}px;
                  padding-top: ${pkgs.lib.toString (builtins.floor (designFactor / 2))}px;
                }

                button:hover {
                  background-color: rgb(49, 50, 68);
                }

                button:focus {
                  background-color: rgb(49, 50, 68);
                }

                grid {
                  box-shadow: 0 0 ${pkgs.lib.toString (builtins.floor (designFactor * 3))}px rgb(49, 50, 68);
                  border-radius: ${pkgs.lib.toString (builtins.floor (designFactor / 2))}px;
                  background-color: rgb(17, 17, 27);
                  padding: ${pkgs.lib.toString (builtins.floor (designFactor / 2))}px;
                }''; # Catppuccin Mocha: "Surface 2" rgb(88, 91, 112), "Text" rgb(205, 214, 244), "Surface 0" rgb(49, 50, 68), "Crust" rgb(17, 17, 27)

              target = "nwg-bar/style.css";
              executable = null;
            };
          };

          dataFile = {
            "SourceGit/Catppuccin_${
              pkgs.lib.strings.toUpper (builtins.substring 0 1 config.catppuccin.flavor)
            }${builtins.substring 1 255 config.catppuccin.flavor}.json" =
              {
                enable = true;

                source = builtins.fetchurl {
                  url = "https://raw.githubusercontent.com/sourcegit-scm/sourcegit-theme/refs/heads/main/themes/Catpuccin_Mocha.json";
                };

                target = "SourceGit/Catppuccin_${
                  pkgs.lib.strings.toUpper (builtins.substring 0 1 config.catppuccin.flavor)
                }${builtins.substring 1 255 config.catppuccin.flavor}.json";
                executable = null;
              }; # Non-Standard Path
          };

          # stateFile = { };

          # cacheFile = { };
        };

        gtk = {
          enable = true;

          font = {
            name = fontPreferences.name.sansSerif;
            package = fontPreferences.package;
            size = fontPreferences.size;
          };

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

          iconTheme = {
            name = "Papirus-Dark";
            package = (
              pkgs.papirus-icon-theme.override {
                color = "black";
              }
            );
          };

          cursorTheme = {
            name = config.home-manager.users.normal.home.pointerCursor.name;
            package = config.home-manager.users.normal.home.pointerCursor.package;
            size = config.home-manager.users.normal.home.pointerCursor.size;
          };

          gtk4 = {
            enable = true;

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            colorScheme = config.home-manager.users.normal.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              package = config.home-manager.users.normal.gtk.cursorTheme.package;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };

          gtk3 = {
            enable = true;

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            colorScheme = config.home-manager.users.normal.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              package = config.home-manager.users.normal.gtk.cursorTheme.package;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };

          gtk2 = {
            enable = true;

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              package = config.home-manager.users.normal.gtk.cursorTheme.package;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };
        };

        qt = {
          enable = true;

          platformTheme.name = "qtct";
          style.name = config.qt.style;

          qt6ctSettings = {
            Fonts = {
              fixed = "\"${fontPreferences.name.monospace},${pkgs.lib.toString fontPreferences.size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0\"";
              general = "\"${fontPreferences.name.sansSerif},${pkgs.lib.toString fontPreferences.size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0\"";
            };

            Appearance = {
              custom_palette = true;
              color_scheme_path = "${config.catppuccin.sources.qt5ct}/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";
              style = "kvantum-dark";

              icon_theme = config.home-manager.users.normal.gtk.iconTheme.name;

              standard_dialogs = "xdgdesktopportal";
            };

            Interface = {
              activate_item_on_single_click = 0; # 0 = Disabled
              buttonbox_layout = 2; # 2 = KDE
              dialog_buttons_have_icons = 0; # 0 = Disabled
              keyboard_scheme = 3; # 3 = KDE
              menus_have_icons = true;
              show_shortcuts_in_context_menus = true;
              toolbutton_style = 4; # 4 = Follow Application Style
              underline_shortcut = 2; # 2 = Enabled
            };
          };

          qt5ctSettings = {
            Appearance = {
              custom_palette = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.custom_palette;
              color_scheme_path = "${config.catppuccin.sources.qt5ct}/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";
              style = "kvantum-dark";

              icon_theme = config.home-manager.users.normal.gtk.iconTheme.name;

              standard_dialogs = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.standard_dialogs;
            };

            Interface = {
              activate_item_on_single_click =
                config.home-manager.users.normal.qt.qt6ctSettings.Interface.activate_item_on_single_click;
              buttonbox_layout = config.home-manager.users.normal.qt.qt6ctSettings.Interface.buttonbox_layout;
              dialog_buttons_have_icons =
                config.home-manager.users.normal.qt.qt6ctSettings.Interface.dialog_buttons_have_icons;
              keyboard_scheme = config.home-manager.users.normal.qt.qt6ctSettings.Interface.keyboard_scheme;
              menus_have_icons = config.home-manager.users.normal.qt.qt6ctSettings.Interface.menus_have_icons;
              show_shortcuts_in_context_menus =
                config.home-manager.users.normal.qt.qt6ctSettings.Interface.show_shortcuts_in_context_menus;
              toolbutton_style = config.home-manager.users.normal.qt.qt6ctSettings.Interface.toolbutton_style;
              underline_shortcut = config.home-manager.users.normal.qt.qt6ctSettings.Interface.underline_shortcut;
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

          gnome-keyring = {
            enable = config.services.gnome.gnome-keyring.enable;
            package = pkgs.gnome-keyring;

            components = [
              "pkcs11"
              "secrets"
            ];
          };

          gpg-agent = {
            enable = config.programs.gnupg.agent.enable;

            enableExtraSocket = config.programs.gnupg.agent.enableExtraSocket;
            enableScDaemon = true;

            enableSshSupport = config.programs.gnupg.agent.enableSSHSupport;
            enableBashIntegration = true;

            pinentry.package = config.programs.gnupg.agent.pinentryPackage;
            noAllowExternalCache = false;
            grabKeyboardAndMouse = true;
          };

          ssh-agent.enable = !config.programs.gnupg.agent.enable;

          network-manager-applet = {
            enable = config.programs.nm-applet.enable;
            package = config.programs.nm-applet.package;
          };

          udiskie = {
            enable = true;
            package = pkgs.udiskie;

            tray = "always";

            automount = true;
            notify = true;

            settings = {
              program_options = {
                menu = "nested";

                terminal = "uwsm-app -- wezterm start --always-new-process --cwd";
                file_manager = "uwsm-app -- xdg-open";

                password_cache = 5; # 5 Minutes

              };

              quickmenu_actions = "all";
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
              transition-time = transitionDuration;
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
                path = "${bgrtPng}";
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
                  path = "${bgrtPng}";
                }
              ];
            }; # Addition
          }; # TODO: Design

          waybar = {
            enable = true;
            package = config.programs.waybar.package;

            systemd = {
              enable = true;

              enableInspect = false;
              enableDebug = config.environment.enableDebugInfo;
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
                spacing = builtins.floor (designFactor / 4); # 4

                modules-left = [
                  "group/backlight-and-idle-inhibitor"
                  "group/wireplumber-and-bluetooth"
                  "battery"
                  "group/cpu-and-load-and-temperature"
                  "group/memory-and-disk"
                  "network"
                ];

                modules-center = [
                  "group/clock-and-user"
                ];

                modules-right = [
                  "systemd-failed-units"
                  "custom/swaynotificationcenter"
                  "tray"
                  "gamemode"
                  "group/taskbar-and-workspaces"
                ];

                "group/backlight-and-idle-inhibitor" = {
                  modules = [
                    "backlight"
                    "idle_inhibitor"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = transitionDuration;
                  };
                  orientation = "inherit";
                };

                backlight = {
                  interval = 1; # 1 Second

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
                  ]; # Only 9 icons are available.

                  tooltip = true;
                  tooltip-format = "{percent}% {icon}";

                  scroll-step = 1.0;
                  reverse-scrolling = false;
                  reverse-mouse-scrolling = false;
                  on-scroll-up = "brightnessctl set +1%";
                  on-scroll-down = "brightnessctl set 1%-";

                  on-click = "uwsm-app -- nwg-displays & uwsm-app -- com.sidevesh.Luminance";
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

                "group/wireplumber-and-bluetooth" = {
                  modules = [
                    "wireplumber"
                    "bluetooth"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = transitionDuration;
                  };
                  orientation = "inherit";
                };

                wireplumber = {
                  only-physical = false;
                  max-volume = 150.0; # According to Maximum Volume in pwvucontrol under Over-Amplification

                  format = "{volume}% {icon} {format_source}";
                  format-muted = "{icon} {format_source}";

                  format-source = " {volume}% ";
                  format-source-muted = "";

                  format-icons = {
                    default = [
                      ""
                      ""
                      ""
                    ]; # Only 3 icons are available.
                    default-muted = "";
                  };

                  tooltip = true;
                  tooltip-format = "Node Nickname: {node_name}\nSource Description: {source_desc}";

                  scroll-step = 1.0;
                  reverse-scrolling = false;
                  reverse-mouse-scrolling = false;
                  on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+";
                  on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";

                  on-click = "uwsm-app -- pwvucontrol & uwsm-app -- helvum";
                  on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                  on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
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

                battery = {
                  design-capacity = false;
                  weighted-average = true;
                  interval = 1; # 1 Second

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
                  ]; # Only 5 icons are available.

                  tooltip = true;
                  tooltip-format = "Capacity: {capacity}%\nPower: {power} W\n{timeTo}\nCycles: {cycles}\nHealth: {health}%";

                  on-click = "uwsm-app -- resources";
                };

                "group/cpu-and-load-and-temperature" = {
                  modules = [
                    "cpu"
                    "load"
                    "temperature"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = transitionDuration;
                  };
                  orientation = "inherit";
                };

                cpu = {
                  interval = 1; # 1 Second

                  format = "{usage}% ";

                  tooltip = true;

                  on-click = "uwsm-app -- resources";
                };

                load = {
                  interval = 1; # 1 Second

                  format = "{} "; # {} = {load1}

                  tooltip = true;

                  on-click = "uwsm-app -- resources";
                };

                temperature = {
                  interval = 1; # 1 Second

                  format = "{temperatureC}°C {icon}";
                  format-critical = "{temperatureC}°C {icon}";
                  format-icons = [
                    ""
                    ""
                    ""
                    ""
                    ""
                  ]; # Only 5 icons are available.

                  tooltip = true;
                  tooltip-format = "{temperatureF}°F\n{temperatureK}K";

                  on-click = "uwsm-app -- resources";
                };

                "group/memory-and-disk" = {
                  modules = [
                    "memory"
                    "disk"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = transitionDuration;
                  };
                  orientation = "inherit";
                };

                memory = {
                  interval = 1; # 1 Second

                  format = "{percentage}% ";

                  tooltip = true;
                  tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                  on-click = "uwsm-app -- resources";
                };

                disk = {
                  path = "/";
                  unit = "GB";
                  interval = 1; # 1 Second

                  format = "{percentage_used}% 󰋊";

                  tooltip = true;
                  tooltip-format = "Total: {specific_total} GB\nUsed: {specific_used} GB ({percentage_used}%)\nFree: {specific_free} GB ({percentage_free}%)";

                  on-click = "uwsm-app -- resources";
                };

                network = {
                  interval = 1; # 1 Second

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

                  on-click = "uwsm-app -- resources";
                };

                "group/clock-and-user" = {
                  modules = [
                    "clock"
                    "user"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = true;
                    transition-duration = transitionDuration;
                  };
                  orientation = "inherit";
                };

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

                user = {
                  interval = 1; # 1 Second

                  format = "{work_d}:{work_H}:{work_M}:{work_S} ";

                  icon = false;

                  open-on-click = false;
                };

                systemd-failed-units = {
                  system = true;
                  user = true;

                  hide-on-ok = false;

                  format = "{nr_failed_system}, {nr_failed_user} ";
                  format-ok = "";

                  on-click = "uwsm-app -- kjournaldbrowser";
                };

                "custom/swaynotificationcenter" = {
                  exec-if = "which swaync-client";
                  exec = "swaync-client --subscribe-waybar";
                  return-type = "json";
                  escape = true;

                  format = "{} {icon}";
                  format-icons = {
                    notification = "<sup></sup>";
                    none = "";

                    inhibited-notification = "<sup></sup>";
                    inhibited-none = "";

                    dnd-notification = "<sup></sup>";
                    dnd-none = "";

                    dnd-inhibited-notification = "<sup></sup>";
                    dnd-inhibited-none = "";
                  };

                  tooltip = true;

                  on-click = "swaync-client --toggle-panel --skip-wait";
                  on-click-middle = "swaync-client --close-all --skip-wait";
                  on-click-right = "swaync-client --toggle-dnd --skip-wait";
                };

                tray = {
                  show-passive-items = true;
                  reverse-direction = false;
                  icon-size = fontPreferences.size;
                  spacing = builtins.floor (designFactor / 4); # 4
                };

                gamemode = {
                  hide-not-running = true;

                  use-icon = false;
                  glyph = "󰊗";
                  format = "{glyph} {count}";
                  format-alt = "Games: {count}";

                  tooltip = true;
                  tooltip-format = "Games Running: {count}";
                };

                "group/taskbar-and-workspaces" = {
                  modules = [
                    "hyprland/workspaces"
                    "wlr/taskbar"
                  ];
                  drawer = {
                    click-to-reveal = false;
                    transition-left-to-right = false;
                    transition-duration = transitionDuration;
                  };
                  orientation = "inherit";
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

                "hyprland/workspaces" = {
                  all-outputs = false;
                  show-special = true;
                  special-visible-only = false;
                  active-only = false;
                  format = "{name}";
                  move-to-monitor = false;

                  on-scroll-up = "hyprctl dispatch \"hl.dsp.focus({workspace = 'e-1'})\"";
                  on-scroll-down = "hyprctl dispatch \"hl.dsp.focus({workspace = 'e+1'})\"";

                  on-click = "hyprctl dispatch \"hl.dsp.focus({ workspace = <id> })\""; # FIXME: Does Not Work
                };
              };
            };

            style = ''
              * {
                font-family: ${fontPreferences.name.sansSerif};
                font-size: ${pkgs.lib.toString fontPreferences.size}px;
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
              #idle_inhibitor,
              #wireplumber,
              #bluetooth,
              #battery,
              #cpu,
              #load,
              #temperature,
              #memory,
              #disk,
              #network,
              #clock,
              #user,
              #systemd-failed-units,
              #custom-swaynotificationcenter,
              #gamemode,
              #window {
                border-radius: ${pkgs.lib.toString designFactor}px;
                background-color: @crust;
                padding: ${pkgs.lib.toString (builtins.floor (designFactor / 8))}px ${
                  pkgs.lib.toString (builtins.floor (designFactor / 2))
                }px;
                color: @text;
              }

              #idle_inhibitor,
              #bluetooth,
              #load,
              #temperature,
              #disk,
              #user {
                margin-left: ${pkgs.lib.toString (builtins.floor (designFactor / 4))}px;
              }

              #idle_inhibitor.deactivated {
                color: @text;
              }

              #idle_inhibitor.activated {
                color: @green;
              }

              #wireplumber.muted,
              #wireplumber.sink-muted,
              #wireplumber.source-muted {
                color: @red;
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

              #battery.warning,
              #temperature.warning {
                color: @peach;
              }

              #battery.critical,
              #temperature.critical {
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

              #custom-swaynotificationcenter {
                font-family: ${fontPreferences.name.monospace};
              }

              #gamemode.running {
                color: @green;
              }

              #workspaces,
              #taskbar,
              #tray {
                background-color: transparent;
              }

              button {
                margin: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 8))}px;
                border-radius: ${pkgs.lib.toString designFactor}px;
                background-color: @crust;
                padding: 0px;
                color: @text;
              }

              button * {
                padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 4))}px;
              }

              button.active {
                background-color: @mantle;
              }

              button:hover {
                background-color: @surface0;
              }

              #window label {
                padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 4))}px;
                font-size: ${pkgs.lib.toString fontPreferences.size}px;
              }

              #tray > widget {
                border-radius: ${pkgs.lib.toString designFactor}px;
                background-color: @crust;
                color: @text;
              }

              #tray image {
                padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 2))}px;
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

          wezterm = {
            enable = true;
            package = pkgs.wezterm;

            enableBashIntegration = true;

            settings = {
              hide_tab_bar_if_only_one_tab = true;

              font = pkgs.lib.generators.mkLuaInline ''wezterm.font("${fontPreferences.name.monospace}")'';
              font_size = fontPreferences.size;
            };
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

          starship = {
            enable = config.programs.starship.enable;
            package = config.programs.starship.package;

            enableBashIntegration = true;

            enableInteractive = config.programs.starship.interactiveOnly;

            presets = config.programs.starship.presets;
            settings = config.programs.starship.settings;
          };

          nix-index = {
            enable = config.programs.nix-index.enable;
            package = config.programs.nix-index.package;

            enableBashIntegration = config.programs.nix-index.enableBashIntegration;
          };

          command-not-found.enable = config.programs.command-not-found.enable;

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

          direnv = {
            enable = config.programs.direnv.enable;
            package = config.programs.direnv.package;

            nix-direnv = {
              enable = config.programs.direnv.nix-direnv.enable;
              package = config.programs.direnv.nix-direnv.package;
            };

            enableBashIntegration = config.programs.direnv.enableBashIntegration;

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
                x11Support = config.programs.hyprland.xwayland.enable;
                xfceSupport = false;
                zfsSupport = true;
              }
            );
          };

          television = {
            enable = config.programs.television.enable;
            package = config.programs.television.package;

            enableBashIntegration = config.programs.television.enableBashIntegration;
          };

          keychain.enable = !config.programs.gnupg.agent.enable;

          gpg = {
            enable = true;
            package = config.programs.gnupg.package;

            mutableKeys = true;
            mutableTrust = true;

            settings = {
              no-comments = false;
            };

            scdaemonSettings = {
              disable-ccid = true;
            };

            dirmngrSettings = {
              allow-version-check = true;
              keyserver = "hkps://keys.openpgp.org/";
            };

            gpgsmSettings = {
              with-key-data = true;
            };
          };

          mcp = {
            enable = true;
          };

          vscodium = {
            enable = true;
            package = (
              pkgs.vscodium.override {
                useVSCodeRipgrep = false;
              }
            );

            mutableExtensionsDir = true;

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
                    bradgashler.htmltagwrap
                    chanhx.crabviz
                    codezombiech.gitignore
                    coolbear.systemd-unit-file
                    cweijan.vscode-database-client2
                    davidanson.vscode-markdownlint
                    dbaeumer.vscode-eslint
                    dendron.adjust-heading-level
                    docker.docker
                    dotenv.dotenv-vscode
                    ecmel.vscode-html-css
                    esbenp.prettier-vscode
                    fabiospampinato.vscode-open-in-github
                    foxundermoon.shell-format
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
                    njpwerner.autodocstring
                    oderwat.indent-rainbow
                    platformio.platformio-vscode-ide
                    quicktype.quicktype
                    rioj7.commandonallfiles
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
                    wmaurer.change-case
                    xdebug.php-debug
                    zainchen.json
                    zhwu95.riscv
                  ]

                  ++ (with pkgs.vscode-extensions.bierner; [
                    color-info
                    docs-view
                    emojisense
                    github-markdown-preview
                    markdown-checkbox
                    markdown-emoji
                    markdown-footnotes
                    markdown-mermaid
                    markdown-preview-github-styles
                  ])

                  ++ (with pkgs.vscode-extensions.dart-code; [
                    dart-code
                    flutter
                  ])

                  ++ (with pkgs.vscode-extensions.formulahendry; [
                    auto-close-tag
                    auto-rename-tag
                  ])

                  ++ (with pkgs.vscode-extensions.github; [
                    vscode-github-actions
                    vscode-pull-request-github
                  ])

                  ++ (with pkgs.vscode-extensions.ms-python; [
                    black-formatter
                    debugpy
                    flake8
                    isort
                    mypy-type-checker
                    pylint
                    python
                  ])

                  ++ (with pkgs.vscode-extensions.ms-vscode; [
                    cmake-tools
                    hexeditor
                    live-server
                    makefile-tools
                    test-adapter-converter
                  ])

                  ++ (with pkgs.vscode-extensions.redhat; [
                    vscode-xml
                    vscode-yaml
                  ])

                  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                    {
                      name = "arb-editor";
                      publisher = "Google";
                      version = "0.2.2";
                      sha256 = "sSYiudnBRFTsio0uNJ6+FOzkjO92wGDvGJYJcRrzWX0=";
                    }

                    {
                      name = "github-local-actions";
                      publisher = "SanjulaGanepola";
                      version = "1.2.5";
                      sha256 = "gc3iOB/ibu4YBRdeyE6nmG72RbAsV0WIhiD8x2HNCfY=";
                    }

                    {
                      name = "pubspec-assist";
                      publisher = "jeroen-meijer";
                      version = "2.4.0";
                      sha256 = "COjlH34kGHTrgd7gCYIozEA3i1KkwHLRU09yaE0TsOk=";
                    }

                    {
                      name = "unique-lines";
                      publisher = "bibhasdn";
                      version = "1.0.0";
                      sha256 = "W0ZpZ6+vjkfNfOtekx5NWOFTyxfWAiB0XYcIwHabFPQ=";
                    }

                    {
                      name = "vscode-serial-monitor";
                      publisher = "ms-vscode";
                      version = "0.13.251128001";
                      sha256 = "eTQcLyF6DMvzDByKLw2KR8PrjVwejsOU60Hew7IOmY8=";
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
                  ]
                  ++ pkgs.lib.optionals config.nixpkgs.config.allowUnfree (
                    with pkgs.vscode-extensions;
                    [
                      ms-vscode.cpptools
                    ]
                  );

                enableUpdateCheck = true;
                enableExtensionUpdateCheck = true;

                enableMcpIntegration = config.home-manager.users.normal.programs.mcp.enable;
              };
            };
          };

          bat = {
            enable = config.programs.bat.enable;
            package = config.programs.bat.package;
            extraPackages = config.programs.bat.extraPackages;
          };

          # brave.nativeMessagingHosts = with pkgs; [
          # ];

          kubecolor = {
            enable = true;
            package = pkgs.kubecolor;

            enableAlias = true;

            settings = {
              kubectl = pkgs.lib.getExe pkgs.kubectl;
              preset = "dark";
            };
          };

          onlyoffice = {
            enable = true;
            package = pkgs.onlyoffice-desktopeditors;
          };

          mangohud = {
            enable = true;
            package = pkgs.mangohud;
          };

          lutris = {
            enable = true;
            package = (
              pkgs.lutris.override {
                steamSupport = config.nixpkgs.config.allowUnfree;
              }
            );

            extraPackages =
              with pkgs;
              [
                gamemode
                gamescope
                protontricks
                vulkan-loader
                vulkan-tools
                winetricks
              ]
              ++ [
                config.home-manager.users.normal.programs.mangohud.package
              ];
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

          hyprland = {
            enable = config.programs.hyprland.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          hyprlock = {
            enable = config.home-manager.users.normal.programs.hyprlock.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            useDefaultConfig = false;
          };

          cursors = {
            enable = config.catppuccin.cursors.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          gtk.icon.enable = config.catppuccin.gtk.icon.enable;

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

          hyprtoolkit = {
            enable = config.catppuccin.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          waybar = {
            enable = config.home-manager.users.normal.programs.waybar.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            mode = "prependImport";
          };

          swaync = {
            enable = config.home-manager.users.normal.services.swaync.enable;

            flavor = config.catppuccin.flavor;

            font = fontPreferences.name.sansSerif;
            fontSize = pkgs.lib.toString fontPreferences.size;
          };

          wezterm = {
            enable = config.home-manager.users.normal.programs.wezterm.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          starship = {
            enable = config.programs.starship.enable;

            flavor = config.catppuccin.flavor;
          };

          fcitx5 = {
            enable = config.catppuccin.fcitx5.enable;
            apply = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            enableRounded = true;
          };

          television = {
            enable = config.programs.television.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          bat = {
            enable = config.programs.bat.enable;

            flavor = config.catppuccin.flavor;
          };

          mangohud = {
            enable = config.home-manager.users.normal.programs.mangohud.enable;

            flavor = config.catppuccin.flavor;
          };

          obs = {
            enable = config.programs.obs-studio.enable;

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
