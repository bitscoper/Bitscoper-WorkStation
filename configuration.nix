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
          -resize ${pkgs.lib.toString (config.specificHardwareConfiguration.screen.width)}x${pkgs.lib.toString (config.specificHardwareConfiguration.screen.height)}\> \
          -gravity center \
          -extent ${pkgs.lib.toString (config.specificHardwareConfiguration.screen.width)}x${pkgs.lib.toString (config.specificHardwareConfiguration.screen.height)} \
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

    ./Modules/Avahi.nix
    ./Modules/bat.nix
    ./Modules/BlueZ.nix
    ./Modules/chrony.nix
    ./Modules/Cine.nix
    ./Modules/cliphist.nix
    ./Modules/Cockpit.nix
    ./Modules/Contour.nix
    ./Modules/CPU-X.nix
    ./Modules/direnv.nix
    ./Modules/Evince.nix
    ./Modules/Fastfetch.nix
    ./Modules/Fcitx_5.nix
    ./Modules/fdroidcl.nix
    ./Modules/Firefox.nix
    ./Modules/Flutter.nix
    ./Modules/GNOME_Keyring.nix
    ./Modules/GNU_Bash.nix
    ./Modules/GNU_GRand_Unified_Bootloader.nix
    ./Modules/GnuPG.nix
    ./Modules/Hardinfo2.nix
    ./Modules/hypridle.nix
    ./Modules/hyprlock.nix
    ./Modules/hyprpaper.nix
    ./Modules/Hyprshot.nix
    ./Modules/Icecast.nix
    ./Modules/Jellyfin.nix
    ./Modules/KeePassXC.nix
    ./Modules/Kubernetes.nix
    ./Modules/LibreOffice.nix
    ./Modules/libvirt.nix
    ./Modules/Loupe.nix
    ./Modules/Lutris.nix
    ./Modules/MariaDB.nix
    ./Modules/Nautilus.nix
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
    ./Modules/Plymouth.nix
    ./Modules/Podman.nix
    ./Modules/polkit.nix
    ./Modules/PostgreSQL.nix
    ./Modules/Qt.nix
    ./Modules/Rofi.nix
    ./Modules/Simple_Desktop_Display_Manager.nix
    ./Modules/Starship.nix
    ./Modules/Sudo.nix
    ./Modules/SwayNotificationCenter.nix
    ./Modules/sysctl.nix
    ./Modules/Syshud.nix
    ./Modules/udiskie.nix
    ./Modules/Ungoogled_Chromium.nix
    ./Modules/vivid.nix
    ./Modules/Waybar.nix
    ./Modules/Waydroid.nix
    ./Modules/Wayscriber.nix
    ./Modules/WayVNC.nix
    ./Modules/Wireshark.nix
    ./Modules/Zed.nix

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
    hostPlatform = {
      system = "${config.specificHardwareConfiguration.cpu.architecture}-linux";
    };

    config = {
      allowAliases = false;
      allowUnfree = true;

      permittedInsecurePackages = pkgs.lib.optionals config.nixpkgs.config.allowUnfree [
        "mbedtls-3.6.1-unstable-2025-08-11"
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
        mkdir --parents /usr/share/i18n
        ln --symbolic --force --no-dereference /run/current-system/sw/share/i18n/locales /usr/share/i18n/locales
      '';
    };

    # userActivationScripts = { };

    stateVersion = "26.11";
  };

  boot = {
    isContainer = false;

    kernel = {
      enable = true;
    };

    kernelPackages = pkgs.linuxPackages_xanmod_latest.extend (
      final: previous: {
        kernel = previous.kernel.override (arguments: {
          kernelPatches = lib.filter (patch: patch.name != "tools-add-128-bit-integer-types-for-aarch64") (
            arguments.kernelPatches or [ ]
          );
        });
      }
    );

    extraModulePackages = with config.boot.kernelPackages; [
      # apfs # FIXME: Build Failure
      # openafs # FIXME: Build Failure
      # zfs_2_4 # Marked as Broken
      bcachefs
      cpupower
      mm-tools
      tmon
      turbostat
    ];

    hardwareScan = true;

    kernelModules = [
      "at24" # SDR/DDR/DDR2/DDR3 SPD and I²C
      "ee1004" # DDR4 SPD
      "spd5118" # DDR5 SPD
    ]
    ++ config.specificHardwareConfiguration.kernelModules; # From hardware-configuration.nix

    blacklistedKernelModules = [
      "efifb"
      "simplefb"
    ];

    extraModprobeConfig = config.specificHardwareConfiguration.boot.extraModprobeConfig; # From hardware-configuration.nix

    kernelParams = [
      "boot.shell_on_fail"
      "initcall_blacklist=simpledrm_platform_driver_init"
      "iommu=pt"
      "mitigations=auto"
      "rd.systemd.show_status=true"
      "rd.udev.log_level=err"
      "splash"
      "threadirqs"
      "udev.log_level=err"
      "udev.log_priority=err"
    ]
    ++ config.specificHardwareConfiguration.boot.kernelParams; # From hardware-configuration.nix

    initrd = {
      enable = true;

      kernelModules = config.boot.kernelModules;
      availableKernelModules = [
        "usb_storage"
        "usbhid"
        "xhci_pci"
      ]
      ++ config.specificHardwareConfiguration.boot.initrd.availableKernelModules; # From hardware-configuration.nix

      systemd = {
        package = config.systemd.package;
      };

      network.enable = true;
    };

    tmp = {
      cleanOnBoot = true;

      zramSettings = {
        fs-type = "ext4";
        compression-algorithm = "zstd";
      };
    };

    kexec.enable = config.boot.crashDump.enable;
    crashDump = {
      enable = true;

      reservedMemory = "128M";
      kernelParams = [
        "1"
        "boot.shell_on_fail"
      ];
    };

    consoleLogLevel = 4; # 4 = KERN_WARNING
  };

  powerManagement = {
    enable = true;

    cpuFreqGovernor = "performance";
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
      "${config.specificHardwareConfiguration.cpu.vendor}" = {
        updateMicrocode = true;
        microcodePackage = pkgs."microcode-${config.specificHardwareConfiguration.cpu.vendor}";
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

    graphics = {
      enable = true;
      enable32Bit = true;

      extraPackages = config.specificHardwareConfiguration.hardware.graphics.extraPackages; # From hardware-configuration.nix
      extraPackages32 = config.specificHardwareConfiguration.hardware.graphics.extraPackages32; # From hardware-configuration.nix
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
        withPolkit = config.security.polkit.enable;
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

      # allowedTCPPorts = [
      # ];
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
    journald = {
      settings = {
        Journal = {
          Audit = "keep";

          ForwardToSyslog = false;
          Storage = "persistent";
        };
      };
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
        libmtp.out
        rtl-sdr
      ];

      extraRules = ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
        DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
        SUBSYSTEM=="backlight", ACTION=="add", KERNEL=="*", MODE="0666" RUN+="${pkgs.coreutils-full}/bin/chmod a+w /sys/class/backlight/%k/brightness"
      ''
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

    accounts-daemon.enable = true;

    fprintd = {
      enable = true;
      package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;

      tod = {
        enable = config.specificHardwareConfiguration.services.fprintd.tod.enable;
        driver = pkgs.lib.optionals config.services.fprintd.tod.enable config.specificHardwareConfiguration.services.fprintd.tod.package;
      };
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

    gpsd = {
      enable = true;

      readonly = true;

      listenany = true;
      port = 2947;

      debugLevel = 0; # 0 = Disabled
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

    usbtop.enable = true;

    nano.enable = false;

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
          withSsh = config.home-manager.users.normal.programs.ssh.enable;
        }
      );

      lfs = {
        enable = true;
        package = pkgs.git-lfs;

        enablePureSSHTransfer = config.home-manager.users.normal.programs.ssh.enable;
      };

      prompt.enable = true;
    };

    dconf = {
      enable = true;

      profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "com/github/huluti/Curtail" = {
              new-file = true;
              png-lossless-level = pkgs.lib.gvariant.mkInt32 6;
              recursive = true;
              webp-lossless-level = pkgs.lib.gvariant.mkInt32 6;
            }; # https://raw.githubusercontent.com/Huluti/Curtail/main/data/com.github.huluti.Curtail.gschema.xml

            "org/gnome/desktop/interface" = {
              gtk-enable-primary-paste = true;
              monospace-font-name = "${fontPreferences.monospace} ${
                pkgs.lib.toString (builtins.floor (designFactor * 1.5))
              }";
            };

            "org/gnome/desktop/privacy" = {
              remember-recent-files = false;
            };

            "org/gnome/desktop/wm/preferences" = {
              button-layout = "appmenu:minimize,maximize,close";
            };

            "org/gnome/Resources" = {
              apps-show-combined-memory = true;
              apps-show-cpu = true;
              apps-show-decoder = true;
              apps-show-drive-read-speed = true;
              apps-show-drive-read-total = true;
              apps-show-drive-write-speed = true;
              apps-show-drive-write-total = true;
              apps-show-encoder = true;
              apps-show-gpu = true;
              apps-show-gpu-memory = true;
              apps-show-memory = true;
              apps-show-swap = true;
              base = "Binary";
              network-bits = false;
              processes-show-combined-memory = true;
              processes-show-commandline = true;
              processes-show-cpu = true;
              processes-show-decoder = true;
              processes-show-drive-read-speed = true;
              processes-show-drive-read-total = true;
              processes-show-drive-write-speed = true;
              processes-show-drive-write-total = true;
              processes-show-encoder = true;
              processes-show-gpu = true;
              processes-show-gpu-memory = true;
              processes-show-id = true;
              processes-show-memory = true;
              processes-show-priority = true;
              processes-show-swap = true;
              processes-show-system-cpu-time = true;
              processes-show-total-cpu-time = true;
              processes-show-user = true;
              processes-show-user-cpu-time = true;
              refresh-speed = "VeryFast";
              show-graph-grids = true;
              show-logical-cpus = true;
              show-virtual-drives = true;
              show-virtual-network-interfaces = true;
              sidebar-meter-type = "Graph";
              temperature-unit = "Celsius";
            };

            "org/gtk/settings/file-chooser" = {
              show-hidden = true;
              sort-directories-first = true;
            };
          };
        }
      ];
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
        # gearlever # FIXME: Build Failure
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
        appimageupdate-qt
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
        brightnessctl
        btfs
        btrfs-assistant
        btrfs-heatmap
        btrfs-progs
        bustle
        butt
        bzip3
        calligraphy
        carburetor
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
        cmake-format
        cmake-lint
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
        curtail
        cve-bin-tool
        cyclonedx-cli
        cyclonedx-python
        d-spy
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
        dtui
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
        evtest-qt
        exfatprogs
        exhibit
        exiftool
        extract-dtb
        f2fs-tools
        fastlane
        fdk_aac
        fdt-viewer
        fdupes
        ffmpegthumbnailer
        ffpb
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
        fwupd-efi
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
        git-big-picture
        git-filter-repo
        git-open
        git-repo
        github-backup
        github-changelog-generator
        github-distributed-owners
        gitlogue
        glab
        glib
        glib-networking
        gnome-characters
        gnome-firmware
        gnome-frog
        gnome-multi-writer
        gnss-sdr
        gnucash
        gnugrep
        gnumake
        gnused
        gnutar
        go-mtpfs
        go2tv
        goldendict-ng
        google-lighthouse
        gource
        gphoto2fs
        gpredict
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
        hyprgraphics
        hyprland-protocols
        hyprmag
        hyprshutdown
        hyprtoolkit
        hyprutils
        hyprwire
        i2c-tools
        ifuse
        imagemagickBig
        imhex
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
        libsecret
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
        millisecond
        mixxx
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
        obexftp
        onionshare-gui
        openafs
        openai-whisper
        openapv
        opencore-amr
        openh264
        openjpeg
        openobex
        openssl
        orbvis
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
        playerctl
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
        resources
        rp-pppoe
        rpi-imager
        rpmextract
        rt-tests
        rtl-sdr-librtlsdr
        runme
        satdump
        satellite
        sbc
        sbom2dot
        sbomnix
        schroedinger
        scorecard
        sdrangel
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
        ugit
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
        xdg-user-dirs
        xdg-user-dirs-gtk
        xdg-utils
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
          gsaslSupport = true;
          gssSupport = true;
          http2Support = true;
          http3Support = true;
          idnSupport = true;
          opensslSupport = true;
          pslSupport = true;

          scpSupport = true;
          websocketSupport = true;
          zlibSupport = true;
          zstdSupport = true;
        })

        (
          (ffmpeg-full.override {
            withAlsa = config.services.pipewire.alsa.enable;
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
            withPulse = config.services.pipewire.pulse.enable;
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
            withSsh = config.home-manager.users.normal.programs.ssh.enable;
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
          pulseaudioSupport = config.services.pipewire.pulse.enable;
          useGtk = true;
          useQt = false;
        })

        (nwg-displays.override {
          hyprlandSupport = true;
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

        (testdisk-qt.override {
          enableExtFs = true;
          enableNtfs = true;
        }) # qphotorec

        (tor-browser.override {
          audioSupport = true;
          libnotifySupport = true;
          libvaSupport = true;
          mediaSupport = true;
          pipewireSupport = config.services.pipewire.enable;
          pulseaudioSupport = config.services.pipewire.pulse.enable;
          waylandSupport = true;
        })

        (wget.override {
          withLibpsl = true;
          withOpenssl = true;
        })
      ]

      ++ (with pkgs.gst_all_1; [
        (gst-libav.override {
          enableDocumentation = config.documentation.enable;
        })

        (gst-plugins-bad.override {
          ajaSupport = true;
          bluezSupport = config.hardware.bluetooth.enable;
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
          enableAlsa = config.services.pipewire.alsa.enable;
          enableCdparanoia = true;
          enableDocumentation = config.documentation.enable;
          enableWayland = true;
        })

        (gst-plugins-good.override {
          enableDocumentation = config.documentation.enable;
          enableJack = true;
          enableWayland = true;
          gtkSupport = true;
          qt6Support = config.qt.enable;
        })

        (gst-plugins-ugly.override {
          enableDocumentation = config.documentation.enable;
          enableGplPlugins = true;
        })

        (gstreamer.override {
          enableDocumentation = config.documentation.enable;
        })

        (zint-qt.override {
          withGUI = true;
        })
      ])

      ++ (with pkgs.kdePackages; [
        kalgebra
        kalzium
        kcachegrind
        kclock
        kcolorchooser
        kdenlive
        kjournald
        kmahjongg
        kmouth
        kontrast
        kshisen
        kwave
      ])

      ++ (with pkgs.linphonePackages; [
        bc-decaf
        bc-ispell
        bc-mbedtls
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
        config.programs.nm-applet.package # Also Provides nm-connection-editor
      ]

      ++ config.boot.extraModulePackages
      ++ config.fonts.packages
      ++ config.hardware.graphics.extraPackages
      ++ config.hardware.graphics.extraPackages32
      ++ config.networking.networkmanager.plugins
      ++ config.programs.nix-ld.libraries
      ++ config.services.udev.packages
      ++ config.xdg.portal.configPackages
      ++ config.xdg.portal.extraPortals

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
      "/share/xdg-desktop-portal"
    ];

    # etc = { };

    variables = {
      # LD_LIBRARY_PATH = pkgs.lib.mkForce (
      #   pkgs.lib.makeLibraryPath config.programs.nix-ld.libraries + ":$LD_LIBRARY_PATH"
      # );

      GI_TYPELIB_PATH = pkgs.lib.mkForce "${pkgs.libportal}/lib/girepository-1.0:${pkgs.libportal-gtk4}/lib/girepository-1.0:GI_TYPELIB_PATH";
    };

    sessionVariables = {
      ADW_DISABLE_PORTAL = 1;

      EGL_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      SDL_VIDEODRIVER = "wayland";
      NIXOS_OZONE_WL = 1;
      ANKI_WAYLAND = 1;
      _JAVA_AWT_WM_NONREPARENTING = "1";

      XCURSOR_THEME = config.home-manager.users.normal.home.pointerCursor.name;
      XCURSOR_SIZE = config.home-manager.users.normal.home.pointerCursor.size;
    }
    // config.specificHardwareConfiguration.environment.sessionVariables;

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

  xdg = {
    sounds.enable = true;
    icons.enable = true;
    menus.enable = true;

    autostart.enable = true;

    portal = {
      enable = true;
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
      ]; # config.programs.hyprland.portalPackage adds pkgs.xdg-desktop-portal-hyprland to it.

      xdgOpenUsePortal = true;
    };

    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      # https://www.iana.org/assignments/media-types/media-types.xhtml
      defaultApplications = {
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

        "application/prs.wavefront-obj" = "io.github.nokse22.Exhibit.desktop";
        "application/vnd.ms-3mfdocument" = "io.github.nokse22.Exhibit.desktop";
        "model/3mf" = "io.github.nokse22.Exhibit.desktop";
        "model/gltf-binary" = "io.github.nokse22.Exhibit.desktop";
        "model/gltf-json" = "io.github.nokse22.Exhibit.desktop";
        "model/iges" = "io.github.nokse22.Exhibit.desktop";
        "model/obj" = "io.github.nokse22.Exhibit.desktop";
        "model/step" = "io.github.nokse22.Exhibit.desktop";
        "model/stl" = "io.github.nokse22.Exhibit.desktop";
        "model/x-other" = "io.github.nokse22.Exhibit.desktop";

        "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
        "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
      };
    };
  };

  gtk.iconCache.enable = true;

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

    gtk.icon.enable = false; # Done Manually Instead
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
          "floppy"
          "fwupd-refresh"
          "gpsd"
          "i2c"
          "input"
          "lp"
          "networkmanager"
          "nm-openvpn"
          "plugdev"
          "render"
          "systemd-journal"
          "tape"
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

          preferXdgDirectories = true;

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
                scale = 1.0;
              }
            ];

            on = {
              _args = [
                "hyprland.start"
                (pkgs.lib.generators.mkLuaInline ''
                  function()
                    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
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
                  "SUPER + mouse_up"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m-1\"})")
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
            ];

            config = {
              general = {
                allow_tearing = true;

                gaps_workspaces = 0;

                layout = "dwindle";

                gaps_in = builtins.floor (designFactor / 4.0);
                gaps_out = {
                  top = builtins.floor (designFactor / 2.0);
                  right = builtins.floor (designFactor / 2.0);
                  bottom = builtins.floor (designFactor / 2.0);
                  left = builtins.floor (designFactor / 2.0);
                };

                float_gaps = builtins.floor (designFactor / 2.0);

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
                  monitor_gap = builtins.floor (designFactor / 2.0);
                  window_gap = builtins.floor (designFactor / 2.0);

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
                rounding = builtins.floor designFactor;
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
                  drag_3fg = 1; # 1 = 3 Fingers
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

                always_follow_on_dnd = true;

                animate_mouse_windowdragging = true;
                animate_manual_resizes = true;

                middle_click_paste = true;

                font_family = fontPreferences.sansSerif;
              };

              layers = {
                layers_hog_keyboard_focus = true;
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

              xwayland.enabled = config.programs.hyprland.xwayland.enable;

              render = {
                cm_enabled = true;
                cm_auto_hdr = 0; # 0 = Off
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
                prefer_hdr = 0; # 0 = Off
              };

              dwindle = {
                force_split = 0; # 0 = Split Follows Mouse
                use_active_for_splits = true;
                smart_split = false;
                preserve_split = true;

                smart_resizing = true;

                precise_mouse_move = true;
              };
            }; # Sorted from "General" to "Quirks" according to the "Configuring > Core > Config options" Page.

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
            "mimeapps.list".force = true;
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
          };

          # stateFile = { };

          # cacheFile = { };
        };

        gtk = {
          enable = true;

          font = {
            name = fontPreferences.sansSerif;
            package = pkgs.nerd-fonts.noto;
            size = builtins.floor (designFactor * 1.5);
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

        services = {
          network-manager-applet = {
            enable = config.programs.nm-applet.enable;
            package = config.programs.nm-applet.package;
          };

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

              mcp-server-git = {
                enabled = true;

                command = "${pkgs.mcp-server-git}/bin/mcp-server-git";
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

          hyprland = {
            enable = config.programs.hyprland.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          cursors = {
            enable = config.catppuccin.cursors.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          gtk.icon.enable = config.catppuccin.gtk.icon.enable;

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
