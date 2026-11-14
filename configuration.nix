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

  homeManagerFlake = builtins.getFlake "github:nix-community/home-manager/master";
  androidSDKCompositionFlake = builtins.getFlake "github:tadfisher/android-nixpkgs/stable";
  catppuccinThemeFlake = builtins.getFlake "github:catppuccin/nix/main";

  # package="$(nix eval --raw nixpkgs#path)/pkgs/development/mobile/androidenv/querypackages.sh"; for type in packages images addons extras licenses; do sh "$package" "$type"; done
  # androidSDKComposition = pkgs.androidenv.composeAndroidPackages {
  #   numLatestPlatformVersions = 1;
  #   platformVersions = [
  #     "28"
  #     "29"
  #     "30"
  #     "31"
  #     "32"
  #     "33"
  #     "34"
  #     "35"
  #     "36"
  #     "36.1"
  #     "37.0"
  #     "37.1"
  #     "latest"
  #   ];
  #   useGoogleAPIs = false;
  #   useGoogleTVAddOns = false;
  #
  #   platformToolsVersion = "latest";
  #   buildToolsVersions = [
  #     "35.0.0"
  #     "36.0.0"
  #     "36.1.0"
  #     "37.0.0"
  #     "latest"
  #   ];
  #
  #   includeNDK = true;
  #   ndkVersions = [
  #     "28.2.13676358"
  #     "29.0.14206865"
  #     "latest"
  #   ];
  #
  #   cmdLineToolsVersion = "latest";
  #   toolsVersion = "latest";
  #
  #   includeCmake = true;
  #   cmakeVersions = [
  #     "3.22.1"
  #     "4.1.2"
  #     "latest"
  #   ];
  #
  #   includeExtras = [
  #     "extras;google;auto"
  #     "extras;google;simulators"
  #   ];
  #
  #   includeEmulator = true;
  #   emulatorVersion = "latest";
  #
  #   includeSystemImages = false; # Disabled Because It Includes All from platformVersions
  #   systemImageTypes = [
  #     "default"
  #   ];
  #   abiVersions =
  #     pkgs.lib.optionals (config.nixpkgs.hostPlatform.system == "x86_64-linux") [
  #       "x86_64"
  #     ]
  #     ++ pkgs.lib.optionals (config.nixpkgs.hostPlatform.system == "aarch64-linux") [
  #       "arm64-v8a"
  #       "armeabi-v7a"
  #     ];
  #
  #   includeSources = false;
  # };

  androidSDKCompositionFromTadFisher =
    androidSDKCompositionFlake.sdk.${config.nixpkgs.hostPlatform.system}
      (
        sdkPkgs: with sdkPkgs; [
          build-tools-35-0-0
          build-tools-36-0-0
          build-tools-36-1-0
          build-tools-37-0-0

          (cmake-3-22-1.overrideAttrs (oldAttributes: {
            passthru = (oldAttributes.passthru or { }) // {
              installSdk = ((oldAttributes.passthru or { }).installSdk or "") + ''
                chmod u+w "$pkgBase/bin/"

                rm -f "$pkgBase/bin/ninja"
                ln -s ${pkgs.ninja}/bin/ninja "$pkgBase/bin/ninja"
              '';
            };
          })) # Fixes Error
          cmake-4-1-2

          cmdline-tools-latest

          emulator

          ndk-28-2-13676358
          ndk-29-0-14206865
          ndk-30-0-16248370

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
          platforms-android-37-0
          platforms-android-37-1
          platforms-android-37-2

          system-images-android-37-0-default-x86-64
        ] # https://github.com/tadfisher/android-nixpkgs/tree/main/channels/
      );

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

  _module.args = {
    inherit
      androidSDKCompositionFromTadFisher
      designFactor
      fontPreferences
      themedBgrtPngFile
      tlsCACertificateFile
      tlsCertificateConcatenatedFile
      tlsCertificateFile
      tlsCertificateFiles
      tlsCertificatePrivateKeyFile
      transitionDuration
      wallpaperFile
      ;
  };

  imports = [
    homeManagerFlake.nixosModules.home-manager
    catppuccinThemeFlake.nixosModules.catppuccin

    ./hardware-configuration.nix

    ./Modules/bat.nix
    ./Modules/BlueZ.nix
    ./Modules/Cine.nix
    ./Modules/Contour.nix
    ./Modules/Fcitx_5.nix
    ./Modules/fdroidcl.nix
    ./Modules/Firefox.nix
    ./Modules/GNU_GRand_Unified_Bootloader.nix
    ./Modules/Icecast.nix
    ./Modules/Jellyfin.nix
    ./Modules/KeePassXC.nix
    ./Modules/LibreOffice.nix
    ./Modules/Loupe.nix
    ./Modules/MariaDB.nix
    ./Modules/Nautilus.nix
    ./Modules/Nocturne.nix
    ./Modules/nwg-bar.nix
    ./Modules/nwg-drawer.nix
    ./Modules/Open_Broadcaster_Software_Studio.nix
    ./Modules/PHP.nix
    ./Modules/PipeWire.nix
    ./Modules/Plymouth.nix
    ./Modules/Podman.nix
    ./Modules/PostgreSQL.nix
    ./Modules/Simple_Desktop_Display_Manager.nix
    ./Modules/Starship.nix
    ./Modules/Ungoogled_Chromium.nix
    ./Modules/vivid.nix
    ./Modules/Waydroid.nix
    ./Modules/Wireshark.nix
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

      # android_sdk.accept_license = config.nixpkgs.config.allowUnfree;
      androidSDKCompositionFromTadFisher.accept_license = config.nixpkgs.config.allowUnfree;
    };

    overlays = [
      (final: previous: {
        coreutils-full = previous.coreutils-full.override {
          aclSupport = true;
          withOpenssl = true;
        };
      })

      (final: previous: {
        ghost-sh = previous.stdenv.mkDerivation {
          pname = "ghost-sh";
          version = "main";

          src = fetchGit {
            url = "https://github.com/h-jangra/Ghost.sh.git";
            ref = "main";
            submodules = true;
          };

          nativeBuildInputs = with previous; [
            zig.hook
          ];

          zigBuildFlags = [
            "-Doptimize=ReleaseFast"
          ];

          installPhase = ''
            runHook preInstall

            install -Dm755 zig-out/bin/ghost $out/bin/ghost
            install -Dm644 ghost.sh $out/share/ghost/ghost.sh

            substituteInPlace $out/share/ghost/ghost.sh --replace-fail '_GHOST_BIN="$(dirname "''${BASH_SOURCE[0]}")/ghost"' "_GHOST_BIN=\"$out/bin/ghost\""
            substituteInPlace $out/share/ghost/ghost.sh --replace-fail 'if ! command -v "$_GHOST_BIN" >/dev/null 2>&1 || [[ ! -t 0 || ! -t 1 || ! -r /dev/tty ]]; then' 'if false; then'

            runHook postInstall
          '';
        };
      }) # Addition

      (final: previous: {
        hardinfo2 = previous.hardinfo2.override {
          printingSupport = true;
        };
      })

      (final: previous: {
        opendm = previous.stdenv.mkDerivation {
          pname = "opendm";
          version = "main";

          src = fetchGit {
            url = "https://github.com/nadermkhan/opendm.git";
            ref = "main";
            submodules = true;
          };

          nativeBuildInputs = with previous; [
            cmake
            pkg-config
            wrapGAppsHook4
          ];

          buildInputs = with previous; [
            curl
            gtk4
            libadwaita
            nlohmann_json
          ];
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

    extraModprobeConfig = ''
      options kvm ignore_msrs=1 report_ignored_msrs=0
    ''
    + config.specificHardwareConfiguration.boot.extraModprobeConfig; # From hardware-configuration.nix

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

    sensor = {
      hddtemp = {
        enable = true;
        unit = "C";
        drives = [
          "/dev/disk/by-path/*"
        ];
      };
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

      "L+ /usr/bin/umu-run - - - - ${pkgs.umu-launcher}/bin/umu-run"

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
      enablePkexecWrapper = true;

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
            "hyprlock"
            "login"
            "polkit-1"
            "sshd"
            "su"
            "sudo"
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
    wrappers = {
      spice-client-glib-usb-acl-helper = {
        source = "${
          (pkgs.spice-gtk.override {
            withPolkit = config.security.polkit.enable;
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

    timeZone = null; # Null = Imparative
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
        game-devices-udev-rules
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

    gnome = {
      gnome-keyring.enable = true;
      sushi.enable = true;
    };

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

    avahi = {
      enable = true;
      package = (
        pkgs.avahi.override {
          gtk3Support = true;
        }
      );

      nssmdns4 = true;
      nssmdns6 = true;

      wideArea = false;

      settings = {
        server = {
          use-ipv4 = true;
          use-ipv6 = true;

          domain-name = config.networking.domain;
          host-name = config.networking.hostName;
        };

        publish = {
          disable-publishing = false;

          publish-domain = true;
          publish-addresses = true;
          publish-workstation = true;
          publish-hinfo = true;

          disable-user-service-publishing = false;
        };
      };

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

    ollama = {
      enable = true;
      package = pkgs.ollama-cpu;

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
      package = pkgs.gamemode;

      enableRenice = true;
    };

    bash = {
      vteIntegration = true;

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
      # interactiveShellInit = '''';
      # promptInit = '''';

      # logout = '''';
    };

    nix-ld = {
      enable = true;
      package = pkgs.nix-ld;

      libraries =
        options.programs.nix-ld.libraries.default
        ++ (with pkgs; [
          gamemode.lib
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
        pkgs.jdk25.override {
          enableGtk = true;
        }
      );

      binfmt = true;
    };

    usbtop.enable = true;

    nano.enable = false;

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
          pipewireSupport = config.services.pipewire.enable;
          pulseSupport = config.services.pipewire.pulse.enable;
          rfkillSupport = true;
          sndioSupport = true;
          systemdSupport = true;
          traySupport = true;
          udevSupport = true;
          upowerSupport = true;
          wireplumberSupport = config.services.pipewire.wireplumber.enable;
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

    virt-manager = {
      enable = true;
      package = (
        pkgs.virt-manager.override {
          spiceSupport = true;
        }
      );
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
        # apkeep # FIXME: Build Failure
        # darling-dmg # Marked as Broken
        # field-monitor # FIXME: Build Failure
        # flake-checker # FIXME: Build Failure
        # gearlever # FIXME: Build Failure
        # genealogos-cli # FIXME: Build Failure
        # markitdown # FIXME: Build Failure
        # newelle # FIXME: Build Failure
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
        android-tools
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
        clang-analyzer
        clang-tools
        clang_22
        clapgrep
        clinfo
        cliphist
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
        filen-desktop
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
        gamepad-mirror
        gawd
        gawk
        gcc
        gcr_4
        gerbolyze
        gh
        gh-contribs
        gh-skyline
        gh2md
        ghatm
        ghost-sh # From config.nixpkgs.overlays
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
        gtk-vnc
        gtkhash
        gucharmap
        guestfs-tools
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
        hyprland-qt-support
        hyprmag
        hyprshot
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
        jstest-gtk
        jxrlib
        karlender
        kdiff3
        kernel-hardening-checker
        kernelshark
        kexec-tools
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
        libde265
        libfreeaptx
        libheif.bin
        libheif.out
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
        lock
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
        mdns-scanner
        mergerfs
        mesa-demos
        metadata-cleaner
        metronome
        mfcuk
        mfoc
        millisecond
        minikube
        mixxx
        monkeys-audio
        morphosis
        mousam
        mp3fs
        mtools
        mtr-gui # mtr --gtk
        nethogs
        nilfs-utils
        ninja
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
        opendm # From config.nixpkgs.overlays
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
        peazip
        pev
        picard
        picard-tools
        pkg-config
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
        protonup-qt
        psmisc
        qalculate-gtk
        qdirstat
        qemu-user
        qemu-utils
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
        rubyPackages.cocoapods
        runme
        satdump
        satellite
        sbc
        sbom2dot
        sbomnix
        schroedinger
        scorecard
        scrcpy
        sdrangel
        seabird
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
        sshfs-fuse
        sslscan
        stdenv.cc.libc.out # Includes Locales
        steam-run-free
        stellarium
        strace
        strace-analyzer
        subfinder
        svt-av1
        swift
        swift-format
        swiftpm
        switcheroo
        syft
        symlinks
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
        virt-v2v
        vorbis-tools
        vulnix
        wafw00f
        wayback-machine-archiver
        wayback_machine_downloader
        waycheck
        wayland-utils
        wayscriber
        webfont-bundler
        websocat
        wev
        whatfiles
        which
        whois
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
        xoscope
        xvidcore
        xz
        yuview
        zenity
        zenmap
        zfs
        zip

        # (cutter.withPlugins (plugins: [
        #   plugins.rz-ghidra
        # ])) # FIXME: Build Failure

        (cmake.override {
          buildDocs = true;
          isMinimalBuild = false;
          useOpenSSL = true;
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
          pulseaudioSupport = config.services.pipewire.pulse.enable;
          useQt = false;
          useGtk = true;
        })

        (writeShellScriptBin "hardinfo2" ''
          exec sudo -E ${hardinfo2}/bin/hardinfo2 "$@"
        '') # With config.security.sudo.extraRules

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

        (spice-gtk.override {
          withPolkit = config.security.polkit.enable;
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
          qt6Support = true;
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
        config.home-manager.users.normal.services.udiskie.package
        config.programs.gnupg.agent.pinentryPackage
        config.programs.nix-index.package
        config.programs.nm-applet.package # Also Provides nm-connection-editor
      ]

      ++ config.boot.extraModulePackages
      ++ config.fonts.packages
      ++ config.hardware.graphics.extraPackages
      ++ config.hardware.graphics.extraPackages32
      ++ config.home-manager.users.normal.programs.lutris.extraPackages
      ++ config.home-manager.users.normal.programs.zed-editor.extraPackages
      ++ config.networking.networkmanager.plugins
      ++ config.programs.nix-ld.libraries
      ++ config.services.udev.packages
      ++ config.virtualisation.libvirtd.qemu.vhostUserPackages
      ++ config.xdg.portal.configPackages
      ++ config.xdg.portal.extraPortals

      ++ pkgs.lib.optionals config.nixpkgs.config.allowUnfree (
        with pkgs;
        [
          # androidSDKComposition.androidsdk
          androidSDKCompositionFromTadFisher
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

      JAVA_HOME = "${config.programs.java.package}/lib/openjdk";
    }
    // pkgs.lib.optionalAttrs config.nixpkgs.config.allowUnfree {
      # ANDROID_HOME = "${androidSDKComposition.androidsdk}/libexec/android-sdk/";
      # ANDROID_SDK_ROOT = "${androidSDKComposition.androidsdk}/libexec/android-sdk/";

      ANDROID_HOME = "${androidSDKCompositionFromTadFisher}/share/android-sdk/";
      ANDROID_SDK_ROOT = "${androidSDKCompositionFromTadFisher}/share/android-sdk/";
    };

    sessionVariables = {
      EDITOR = "zeditor --wait";
      VISUAL = "zeditor --wait";
      GIT_EDITOR = "zeditor --wait";

      ADW_DISABLE_PORTAL = 1;

      EGL_PLATFORM = "wayland";
      GDK_BACKEND = "wayland";
      QT_QPA_PLATFORM = "wayland";
      SDL_VIDEODRIVER = "wayland";
      WINE_DRIVER = "wayland";
      NIXOS_OZONE_WL = 1;
      ANKI_WAYLAND = 1;
      _JAVA_AWT_WM_NONREPARENTING = "1";

      XCURSOR_THEME = config.home-manager.users.normal.home.pointerCursor.name;
      XCURSOR_SIZE = config.home-manager.users.normal.home.pointerCursor.size;

      VKD3D_CONFIG = "vkd3d_shader_cache";
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
        config.home-manager.users.normal.services.gnome-keyring.package
        pkgs.xdg-desktop-portal-gtk
      ]; # config.programs.hyprland.portalPackage adds pkgs.xdg-desktop-portal-hyprland to it.

      xdgOpenUsePortal = true;
    };

    mime = {
      enable = true;

      addedAssociations = config.xdg.mime.defaultApplications;

      # https://www.iana.org/assignments/media-types/media-types.xhtml
      defaultApplications = {
        "application/bzip2" = "peazip.desktop";
        "application/gzip" = "peazip.desktop";
        "application/vnd.android.package-archive" = "peazip.desktop";
        "application/vnd.debian.binary-package" = "peazip.desktop";
        "application/vnd.ms-cab-compressed" = "peazip.desktop";
        "application/vnd.rar" = "peazip.desktop";
        "application/x-7z-compressed" = "peazip.desktop";
        "application/x-7z-compressed-tar" = "peazip.desktop";
        "application/x-ace" = "peazip.desktop";
        "application/x-alz" = "peazip.desktop";
        "application/x-ar" = "peazip.desktop";
        "application/x-archive" = "peazip.desktop";
        "application/x-arj" = "peazip.desktop";
        "application/x-brotli" = "peazip.desktop";
        "application/x-bzip" = "peazip.desktop";
        "application/x-bzip-brotli-tar" = "peazip.desktop";
        "application/x-bzip-compressed-tar" = "peazip.desktop";
        "application/x-bzip1" = "peazip.desktop";
        "application/x-bzip1-compressed-tar" = "peazip.desktop";
        "application/x-bzip2" = "peazip.desktop";
        "application/x-bzip2-compressed-tar" = "peazip.desktop";
        "application/x-cabinet" = "peazip.desktop";
        "application/x-cd-image" = "peazip.desktop";
        "application/x-chrome-extension" = "peazip.desktop";
        "application/x-compress" = "peazip.desktop";
        "application/x-compressed-tar" = "peazip.desktop";
        "application/x-cpio" = "peazip.desktop";
        "application/x-deb" = "peazip.desktop";
        "application/x-ear" = "peazip.desktop";
        "application/x-gtar" = "peazip.desktop";
        "application/x-gzip" = "peazip.desktop";
        "application/x-java-archive" = "peazip.desktop";
        "application/x-lha" = "peazip.desktop";
        "application/x-lhz" = "peazip.desktop";
        "application/x-lrzip" = "peazip.desktop";
        "application/x-lrzip-compressed-tar" = "peazip.desktop";
        "application/x-lz4" = "peazip.desktop";
        "application/x-lz4-compressed-tar" = "peazip.desktop";
        "application/x-lzip" = "peazip.desktop";
        "application/x-lzip-compressed-tar" = "peazip.desktop";
        "application/x-lzma" = "peazip.desktop";
        "application/x-lzma-compressed-tar" = "peazip.desktop";
        "application/x-lzop" = "peazip.desktop";
        "application/x-ms-dos-executable" = "peazip.desktop";
        "application/x-ms-wim" = "peazip.desktop";
        "application/x-rar" = "peazip.desktop";
        "application/x-rar-compressed " = "peazip.desktop";
        "application/x-rar-compressed" = "peazip.desktop";
        "application/x-rpm" = "peazip.desktop";
        "application/x-rzip" = "peazip.desktop";
        "application/x-rzip-compressed-tar" = "peazip.desktop";
        "application/x-source-rpm" = "peazip.desktop";
        "application/x-stuffit" = "peazip.desktop";
        "application/x-tar" = "peazip.desktop";
        "application/x-tarz" = "peazip.desktop";
        "application/x-tzo" = "peazip.desktop";
        "application/x-war" = "peazip.desktop";
        "application/x-xar" = "peazip.desktop";
        "application/x-xz" = "peazip.desktop";
        "application/x-xz-compressed-tar" = "peazip.desktop";
        "application/x-zip" = "peazip.desktop";
        "application/x-zip-compressed" = "peazip.desktop";
        "application/x-zoo" = "peazip.desktop";
        "application/x-zstd-compressed-tar" = "peazip.desktop";
        "application/zip" = "peazip.desktop";
        "application/zstd" = "peazip.desktop";

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

        "application/gml+xml" = "dev.zed.Zed.desktop";
        "application/rdf+xml" = "dev.zed.Zed.desktop";
        "application/rss+xml" = "dev.zed.Zed.desktop";
        "application/x-zerosize" = "dev.zed.Zed.desktop";
        "application/xhtml+xml" = "dev.zed.Zed.desktop";
        "application/xhtml_xml" = "dev.zed.Zed.desktop";
        "application/xml" = "dev.zed.Zed.desktop";
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

        "application/illustrator" = "org.gnome.Evince.desktop";
        "application/oxps" = "org.gnome.Evince.desktop";
        "application/pdf" = "org.gnome.Evince.desktop";
        "application/postscript" = "org.gnome.Evince.desktop";
        "application/vnd.comicbook+zip" = "org.gnome.Evince.desktop";
        "application/vnd.comicbook-rar" = "org.gnome.Evince.desktop";
        "application/vnd.ms-xpsdocument" = "org.gnome.Evince.desktop";
        "application/x-bzdvi" = "org.gnome.Evince.desktop";
        "application/x-bzpdf" = "org.gnome.Evince.desktop";
        "application/x-bzpostscript" = "org.gnome.Evince.desktop";
        "application/x-cb7" = "org.gnome.Evince.desktop";
        "application/x-cbr" = "org.gnome.Evince.desktop";
        "application/x-cbt" = "org.gnome.Evince.desktop";
        "application/x-cbz" = "org.gnome.Evince.desktop";
        "application/x-dvi" = "org.gnome.Evince.desktop";
        "application/x-ext-cb7" = "org.gnome.Evince.desktop";
        "application/x-ext-cbr" = "org.gnome.Evince.desktop";
        "application/x-ext-cbt" = "org.gnome.Evince.desktop";
        "application/x-ext-cbz" = "org.gnome.Evince.desktop";
        "application/x-ext-djv" = "org.gnome.Evince.desktop";
        "application/x-ext-djvu" = "org.gnome.Evince.desktop";
        "application/x-ext-dvi" = "org.gnome.Evince.desktop";
        "application/x-ext-eps" = "org.gnome.Evince.desktop";
        "application/x-ext-pdf" = "org.gnome.Evince.desktop";
        "application/x-ext-ps" = "org.gnome.Evince.desktop";
        "application/x-gzdvi" = "org.gnome.Evince.desktop";
        "application/x-gzpdf" = "org.gnome.Evince.desktop";
        "application/x-gzpostscript" = "org.gnome.Evince.desktop";
        "application/x-xzpdf" = "org.gnome.Evince.desktop";

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
          "avahi"
          "cdrom"
          "dialout"
          "disk"
          "floppy"
          "fwupd-refresh"
          "gamemode"
          "gpsd"
          "i2c"
          "input"
          "kvm"
          "libvirtd"
          "lp"
          "networkmanager"
          "nm-openvpn"
          "plugdev"
          "qemu-libvirtd"
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

                    hl.exec_cmd("uwsm-app -- wl-paste --type text --watch cliphist store")
                    hl.exec_cmd("uwsm-app -- wl-paste --type image --watch cliphist store")
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
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"cliphist list | rofi -dmenu -sync -window-title 'Clipboard' -p 'Clipboard' | cliphist decode | wl-copy\")")
                ];
              }

              {
                _args = [
                  "SUPER + ALT + RETURN"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"cmd=$(compgen -c | sort -u | rofi -dmenu -sync -window-title 'Commands' -p 'Commands'); [ -n \\\"$cmd\\\" ] && uwsm-app -- ${config.customOptions.executableNameOfTerminalEmulator} bash -ic \\\"$cmd; bash -i\\\"\")")
                ];
              }

              {
                _args = [
                  "SUPER + E"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- dev.zed.Zed.desktop\")")
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
          desktopEntries = {
            cpu-x =
              let
                desktopFile = "${pkgs.cpu-x}/share/applications/io.github.thetumultuousunicornofdarkness.cpu-x.desktop";

                get =
                  key:
                  pkgs.runCommand "${key}_from_CPU-X_Desktop_File" { } ''
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
                  pkgs.runCommand "${key}_from_Hardinfo2_Desktop_File" { } ''
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

        qt = {
          enable = true;

          platformTheme.name = "qtct";
          style.name = config.qt.style;

          qt6ctSettings = {
            Fonts = {
              fixed = "\"${fontPreferences.monospace},${
                pkgs.lib.toString (builtins.floor (designFactor * 1.5))
              },-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0\"";
              general = "\"${fontPreferences.sansSerif},${
                pkgs.lib.toString (builtins.floor (designFactor * 1.5))
              },-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0\"";
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
              color_scheme_path = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.color_scheme_path;
              style = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.style;

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

                terminal = "uwsm-app -- ${config.customOptions.executableNameOfTerminalEmulator} ${config.customOptions.workingDirectoryFlagOfTerminalEmulator}";
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
                path = wallpaperFile;
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
                screencopy_mode = 0; # 0 = GPU Accelerated
                immediate_render = true;
                fractional_scaling = 2; # 2 = Automatic

                hide_cursor = false;

                ignore_empty_input = true;
                text_trim = false;
              };

              auth = {
                pam = {
                  enabled = true;
                  module = "hyprlock";
                };

                fingerprint = {
                  enabled = true;

                  ready_message = "Scan Fingerprint";
                  present_message = "Scanning Fingerprint";
                };
              };

              animations = {
                enabled = true;
              };

              background = [
                {
                  monitor = ""; # "" = All
                  path = wallpaperFile;
                }
              ];

              label = [
                {
                  monitor = ""; # "" = All
                  halign = "center";
                  valign = "top";
                  position = "0, -${
                    pkgs.lib.toString (builtins.floor (config.specificHardwareConfiguration.screen.height * 0.10))
                  }";

                  text_align = "center";
                  font_family = fontPreferences.sansSerif;
                  font_size = builtins.floor (designFactor * 8.0);
                  color = "\$text";
                  text = "\$TIME12";
                }

                {
                  monitor = ""; # "" = All
                  halign = "center";
                  valign = "bottom";
                  position = "0, ${
                    pkgs.lib.toString (builtins.floor (config.specificHardwareConfiguration.screen.height * 0.04))
                  }";

                  text_align = "center";
                  font_family = fontPreferences.sansSerif;
                  font_size = builtins.floor (designFactor * 1.5);
                  color = "\$lavender";
                  text = "\$FPRINTPROMPT";
                }
              ];

              input-field = [
                {
                  monitor = ""; # "" = All
                  halign = "center";
                  valign = "bottom";
                  position = "0, ${
                    pkgs.lib.toString (builtins.floor (config.specificHardwareConfiguration.screen.height * 0.10))
                  }";

                  size = "${pkgs.lib.toString (builtins.floor (designFactor * 42.0))}, ${
                    pkgs.lib.toString (builtins.floor (designFactor * 6.0))
                  }";
                  rounding = builtins.floor (designFactor * 2.0);
                  outline_thickness = 1;
                  outer_color = "\$surface2";
                  shadow_passes = 0; # 0 = Disabled

                  inner_color = "\$mantle";

                  hide_input = false;
                  font_family = fontPreferences.sansSerif;
                  font_color = "\$lavender";
                  placeholder_text = "Enter Password for $DESC";
                  dots_center = true;
                  dots_rounding = -1;

                  fade_on_empty = true;

                  invert_numlock = false;
                  capslock_color = "\$mauve";
                  numlock_color = "\$mauve";
                  bothlock_color = "\$mauve";

                  check_color = "\$blue";
                  fail_color = "\$red";
                  fail_text = "$FAIL <b>($ATTEMPTS)</b>";
                }
              ];
            };
          };

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
                margin-top = builtins.floor (designFactor / 2.0);
                margin-right = builtins.floor (designFactor / 2.0);
                margin-bottom = 0;
                margin-left = builtins.floor (designFactor / 2.0);

                fixed-center = true;
                spacing = builtins.floor (designFactor / 2.0);

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

                  on-click = "uwsm-app -- nwg-displays.desktop & uwsm-app -- com.sidevesh.Luminance.desktop";
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

                  on-click = "uwsm-app -- pwvucontrol & uwsm-app -- org.pipewire.Helvum.desktop";
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

                  on-click = "uwsm-app -- io.github.kaii_lb.Overskride.desktop";
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

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
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

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
                };

                load = {
                  interval = 1; # 1 Second

                  format = "{} "; # {} = {load1}

                  tooltip = true;

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
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

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
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

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
                };

                disk = {
                  path = "/";
                  unit = "GB";
                  interval = 1; # 1 Second

                  format = "{percentage_used}% 󰋊";

                  tooltip = true;
                  tooltip-format = "Total: {specific_total} GB\nUsed: {specific_used} GB ({percentage_used}%)\nFree: {specific_free} GB ({percentage_free}%)";

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
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

                  on-click = "uwsm-app -- org.gnome.Resources.desktop";
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

                  on-click = "uwsm-app -- org.kde.kjournaldbrowser.desktop";
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
                  icon-size = builtins.floor (designFactor * 1.5);
                  spacing = builtins.floor (designFactor / 2.0);
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
                  icon-size = builtins.floor (designFactor * 1.5);
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

                  on-scroll-up = "hyprctl dispatch \"hl.dsp.focus({workspace = 'm-1'})\"";
                  on-scroll-down = "hyprctl dispatch \"hl.dsp.focus({workspace = 'm+1'})\"";

                  on-click = "hyprctl dispatch \"hl.dsp.focus({ workspace = <id> })\""; # FIXME: Does Not Work
                };
              };
            };

            style = ''
              * {
                font-family: ${fontPreferences.sansSerif};
                font-size: ${pkgs.lib.toString (builtins.floor (designFactor * 1.5))}px;
                font-weight: 500; /* Medium */
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
              #gamemode {
                border: 1px solid @surface1;
                border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
                background-color: @mantle;
                padding: ${
                  pkgs.lib.toString (builtins.floor (designFactor / 4.0))
                }px ${pkgs.lib.toString (builtins.floor designFactor)}px;
                color: @lavender;
              }

              #idle_inhibitor,
              #bluetooth,
              #load,
              #temperature,
              #disk,
              #user {
                margin-left: ${pkgs.lib.toString (builtins.floor (designFactor / 2.0))}px;
              }

              #backlight,
              #cpu,
              #load,
              #temperature,
              #memory,
              #disk,
              #clock,
              #user,
              #custom-swaynotificationcenter {
                transition: background-color ${pkgs.lib.toString transitionDuration}ms;
              }

              #idle_inhibitor,
              #wireplumber,
              #bluetooth,
              #battery,
              #network,
              #systemd-failed-units,
              #gamemode {
                transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
              }

              #idle_inhibitor.deactivated {
                color: @lavender;
              }

              #idle_inhibitor.activated {
                color: @blue;
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
                color: @lavender;
              }

              #bluetooth.discovering,
              #bluetooth.connected {
                color: @blue;
              }

              #battery.critical {
                color: @red;
              }

              #battery.warning {
                color: @mauve;
              }

              #battery.charging {
                color: @blue;
              }

              #battery.full,
              #battery.plugged {
                color: @lavender;
              }

              #temperature.warning {
                color: @mauve;
              }

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
                color: @lavender;
              }

              #systemd-failed-units.degraded {
                color: @red;
              }

              #systemd-failed-units.ok {
                color: @lavender;
              }

              #gamemode.running {
                color: @blue;
              }

              #backlight:hover,
              #idle_inhibitor:hover,
              #wireplumber:hover,
              #bluetooth:hover,
              #battery:hover,
              #cpu:hover,
              #load:hover,
              #temperature:hover,
              #memory:hover,
              #disk:hover,
              #network:hover,
              #clock:hover,
              #user:hover,
              #systemd-failed-units:hover,
              #custom-swaynotificationcenter:hover,
              #gamemode:hover {
                background-color: @surface0;
              }

              #workspaces,
              #taskbar {
                background-color: transparent;
              }

              #workspaces button,
              #taskbar button {
                margin: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 4.0))}px 0px ${
                  pkgs.lib.toString (builtins.floor (designFactor / 4.0))
                }px;
                border: 1px solid @surface1;
                border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
                background-color: @mantle;
                padding: 0px;
                color: @lavender;
                transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
              }

              #workspaces button {
                padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 2.0))}px 0px ${
                  pkgs.lib.toString (builtins.floor (designFactor / 2.0))
                }px;
              }

              button * {
                padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 4))}px;
              }

              #workspaces button.active,
              #taskbar button.active {
                color: @blue;
              }

              #workspaces button:hover,
              #taskbar button:hover {
                background-color: @surface0;
              }

              #tray {
                background-color: transparent;
              }

              #tray > widget {
                border: 1px solid @surface1;
                border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
                background-color: @mantle;
                color: @lavender;
                transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
              }

              #tray > widget.passive {
                color: @lavender;
                -gtk-icon-effect: dim;
              }

              #tray > widget.active {
                color: @blue;
              }

              #tray > widget.needs-attention {
                color: @mauve;
                -gtk-icon-effect: highlight;
              }

              #tray > widget:hover {
                background-color: @surface0;
              }

              #tray image {
                padding: 0px ${pkgs.lib.toString (builtins.floor designFactor)}px 0px ${pkgs.lib.toString (builtins.floor designFactor)}px;
              }
            '';
          };

          bash = {
            enable = true;
            package = pkgs.bashInteractive;

            enableVteIntegration = config.programs.bash.vteIntegration;
            enableCompletion = config.programs.bash.completion.enable;

            shellOptions = [
              "-extdebug"
              "autocd"
              "checkhash"
              "checkjobs"
              "checkwinsize"
              "cmdhist"
              "dotglob"
              "extglob"
              "globstar"
              "gnu_errfmt"
              "histappend"
              "lithist"
            ];

            sessionVariables = {
              HISTTIMEFORMAT = "%F %T ";
            };

            shellAliases = config.programs.bash.shellAliases;

            # profileExtra = '''';

            initExtra = ''
              export PROMPT_COMMAND="history -a"

              export _GHOST_BIN="${pkgs.ghost-sh}/bin/ghost"
              if [[ -f "${pkgs.ghost-sh}/share/ghost/ghost.sh" ]]; then
                source "${pkgs.ghost-sh}/share/ghost/ghost.sh"
              fi
            '';

            # logoutExtra = '''';
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

          nix-index = {
            enable = config.programs.nix-index.enable;
            package = config.programs.nix-index.package;

            enableBashIntegration = config.programs.nix-index.enableBashIntegration;
          };

          command-not-found.enable = config.programs.command-not-found.enable;

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

          rofi = {
            enable = true;
            package = (
              pkgs.rofi.override {
                rofi-unwrapped = (
                  pkgs.rofi-unwrapped.override {
                    waylandSupport = true;
                    x11Support = config.programs.hyprland.xwayland.enable;
                  }
                );

                symlink-dmenu = true;
              }
            );

            settings = {
              modes = "run";

              font = "${fontPreferences.sansSerif} ${pkgs.lib.toString (builtins.floor (designFactor * 1.5))}";
              show-icons = false; # For dmenu
              icon-theme = config.home-manager.users.normal.gtk.iconTheme.name;

              global-kb = true;
              steal-focus = true;
              click-to-exit = true;
              hover-select = true;

              case-sensitive = false;
              fixed-num-lines = true;
              sort = true;
              cycle = true;

              disable-history = true;
              terminal = config.customOptions.executableNameOfTerminalEmulator;
            };

            theme =
              let
                makeLiteral = value: {
                  _type = "literal";
                  inherit value;
                };
              in
              {
                "*" = {
                  # Catppuccin Mocha
                  rosewater = makeLiteral "#f5e0dc";
                  flamingo = makeLiteral "#f2cdcd";
                  pink = makeLiteral "#f5c2e7";
                  mauve = makeLiteral "#cba6f7";
                  red = makeLiteral "#f38ba8";
                  maroon = makeLiteral "#eba0ac";
                  peach = makeLiteral "#fab387";
                  yellow = makeLiteral "#f9e2af";
                  green = makeLiteral "#a6e3a1";
                  teal = makeLiteral "#94e2d5";
                  sky = makeLiteral "#89dceb";
                  sapphire = makeLiteral "#74c7ec";
                  blue = makeLiteral "#89b4fa";
                  lavender = makeLiteral "#b4befe";
                  text = makeLiteral "#cdd6f4";
                  subtext1 = makeLiteral "#bac2de";
                  subtext0 = makeLiteral "#a6adc8";
                  overlay2 = makeLiteral "#9399b2";
                  overlay1 = makeLiteral "#7f849c";
                  overlay0 = makeLiteral "#6c7086";
                  surface2 = makeLiteral "#585b70";
                  surface1 = makeLiteral "#45475a";
                  surface0 = makeLiteral "#313244";
                  base = makeLiteral "#1e1e2e";
                  mantle = makeLiteral "#181825";
                  crust = makeLiteral "#11111b";

                  background-color = makeLiteral "@base";
                  text-color = makeLiteral "@text";
                };

                window = {
                  border = makeLiteral "1px";
                  border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                  border-color = makeLiteral "@surface2";
                  padding = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                };

                mainbox = {
                  border = makeLiteral "0px";
                  padding = makeLiteral "0px";
                };

                inputbar = {
                  margin = makeLiteral "0px 0px ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px 0px";
                  border = makeLiteral "1px";
                  border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                  border-color = makeLiteral "@surface2";
                  background-color = makeLiteral "@mantle";
                  padding = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                  spacing = makeLiteral "0px";
                  children = map makeLiteral [
                    "prompt"
                    "textbox-prompt-colon"
                    "entry"
                    "num-filtered-rows"
                    "textbox-num-sep"
                    "num-rows"
                    "case-indicator"
                  ];
                };

                prompt = {
                  background-color = makeLiteral "@mantle";
                  spacing = makeLiteral "0px";
                  text-color = makeLiteral "@lavender";
                };

                textbox-prompt-colon = {
                  expand = false;
                  margin = makeLiteral "0px 0.3000em 0.0000em 0.0000em";
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@lavender";
                  str = ":";
                };

                entry = {
                  background-color = makeLiteral "@mantle";
                  spacing = makeLiteral "0px";
                  placeholder-color = makeLiteral "@overlay0";
                  placeholder = "Search";
                  cursor = makeLiteral "text";
                };

                num-filtered-rows = {
                  expand = false;
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@lavender";
                };

                textbox-num-sep = {
                  expand = false;
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@lavender";
                  str = "/";
                };

                num-rows = {
                  expand = false;
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@lavender";
                };

                case-indicator = {
                  background-color = makeLiteral "@mantle";
                  spacing = makeLiteral "0px";
                  text-color = makeLiteral "@lavender";
                };

                message = {
                  margin = makeLiteral "0px 0px ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px 0px";
                  border = makeLiteral "0px";
                  padding = makeLiteral "0px";
                };

                textbox = {
                  horizontal-align = makeLiteral "0.5";
                  text-color = makeLiteral "@lavender";
                };

                listview = {
                  fixed-height = makeLiteral "0px";
                  border = makeLiteral "0px";
                  scrollbar = true;
                  padding = makeLiteral "0px";
                  spacing = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                };

                element = {
                  border = makeLiteral "0px";
                  border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                  padding = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                  spacing = makeLiteral "0px";
                  cursor = makeLiteral "pointer";
                };

                "element normal.normal" = {
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@text";
                };

                "element normal.urgent" = {
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@red";
                };

                "element normal.active" = {
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@blue";
                };

                "element alternate.normal" = {
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@text";
                };

                "element alternate.urgent" = {
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@red";
                };

                "element alternate.active" = {
                  background-color = makeLiteral "@mantle";
                  text-color = makeLiteral "@blue";
                };

                "element selected.normal" = {
                  background-color = makeLiteral "@surface0";
                  text-color = makeLiteral "@lavender";
                };

                "element selected.urgent" = {
                  background-color = makeLiteral "@surface0";
                  text-color = makeLiteral "@red";
                };

                "element selected.active" = {
                  background-color = makeLiteral "@surface0";
                  text-color = makeLiteral "@blue";
                };

                element-icon = {
                  margin = makeLiteral "0px ${pkgs.lib.toString (builtins.floor designFactor)} 0px 0px";
                  background-color = makeLiteral "transparent";
                  size = makeLiteral "1.0000em";
                  text-color = makeLiteral "inherit";
                  cursor = makeLiteral "inherit";
                };

                element-text = {
                  background-color = makeLiteral "transparent";
                  text-color = makeLiteral "inherit";
                  cursor = makeLiteral "inherit";
                  highlight = makeLiteral "inherit";
                };

                scrollbar = {
                  width = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                  border = makeLiteral "1px";
                  border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                  border-color = makeLiteral "@surface1";
                  background-color = makeLiteral "@mantle";
                  padding = makeLiteral "0px";
                  handle-width = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                  handle-color = makeLiteral "@lavender";
                  cursor = makeLiteral "pointer";
                };
              };
          };

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

          zed-editor = {
            enable = true;
            package = (
              pkgs.zed-editor.override {
                buildRemoteServer = config.home-manager.users.normal.programs.zed-editor.installRemoteServer;
              }
            );
            installRemoteServer = true;

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
                flutter
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
              "git-firefly"
              "github-actions"
              "github-activity-summarizer"
              "gitignore-templates"
              "graphql"
              "graphviz"
              "groovy"
              "html-snippets"
              "http"
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
              line_indicator_format = "long";

              project_panel = {
                dock = "left";
                button = true;

                scrollbar = {
                  show = "auto";
                };

                sticky_scroll = true;
                entry_spacing = "comfortable";

                indent_guides = {
                  show = "always";
                };

                hide_root = false;
                hide_hidden = false;
                sort_mode = "directories_first";

                file_icons = true;
                git_status = true;
                show_diagnostics = "all";

                drag_and_drop = true;
              };

              file_finder = {
                file_icons = true;
              };

              outline_panel = {
                dock = "left";
                button = true;

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
                dock = "left";
                button = true;

                scrollbar = {
                  show = "auto";
                };
              };

              collaboration_panel = {
                dock = "right";
                button = true;
              };

              bottom_dock_layout = "full";
              terminal = {
                dock = "bottom";
                flexible = true;
                button = true;

                toolbar = {
                  breadcrumbs = true;
                };

                scrollbar = {
                  show = "auto";
                };

                font_family = fontPreferences.monospace;
                font_size = builtins.floor (designFactor * 2.0);
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
                  EDITOR = "zeditor --wait";
                  VISUAL = "zeditor --wait";
                  GIT_EDITOR = "zeditor --wait";
                };
              };

              debugger = {
                dock = "left";
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

              drag_and_drop_selection = {
                enabled = true;
              };

              edit_predictions = {
                mode = "subtle";

                provider = "ollama";
                ollama = { };
              };

              agent = {
                enabled = true;

                dock = "right";
                flexible = true;
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

              journal = {
                hour_format = "hour12";
              };

              image_viewer = {
                unit = "binary";
              };

              session = {
                restore_unsaved_buffers = true;
              };

              use_system_prompts = true;
              use_system_path_prompts = true;
              close_on_file_delete = false;
              confirm_quit = true;

              vim_mode = false;
              helix_mode = false;
              hide_mouse = "never";

              show_call_status_icon = true;

              ui_font_family = fontPreferences.sansSerif;
              ui_font_size = builtins.floor (designFactor * 2.0);

              agent_ui_font_family = fontPreferences.sansSerif;
              agent_ui_font_size = builtins.floor (designFactor * 2.0);

              buffer_font_family = fontPreferences.monospace;
              buffer_font_size = builtins.floor (designFactor * 2.0);
              buffer_line_height = "comfortable";

              agent_buffer_font_family = fontPreferences.monospace;
              agent_buffer_font_size = builtins.floor (designFactor * 2.0);

              mouse_wheel_zoom = true;

              cursor_shape = "bar";
              cursor_blink = true;

              soft_wrap = "editor_width";
              show_whitespaces = "all";
              show_wrap_guides = true;
              lsp_document_colors = "inlay";
              colorize_brackets = true;
              current_line_highlight = "all";
              selection_highlight = true;
              rounded_selection = true;

              inline_code_actions = true;
              hover_popover_enabled = true;
              hover_popover_sticky = true;
              code_lens = "on";

              disable_ai = false;
              show_completions_on_input = true;
              show_completion_documentation = true;
              completion_menu_scrollbar = "auto";
              auto_signature_help = true;
              show_signature_help_after_edits = true;

              use_auto_surround = true;
              extend_comment_on_newline = false;
              auto_indent = "syntax_aware";
              auto_indent_on_paste = true;
              hard_tabs = false;
              tab_size = 2;

              line_ending = "detect";
              format_on_save = "on";
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

                "HTML" = [
                  "*.svg"
                  "*.xhtml"
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

                "JSON" = [
                  "*.webmanifest"
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

            # userTasks = {
            # };

            # userDebug = {
            # };

            # userKeymaps = {
            # };

            defaultEditor = false; # Done Manually Instead
          };

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

              mcp-k8s-go = {
                enabled = true;

                command = "${pkgs.mcp-k8s-go}/bin/mcp-k8s-go";
              };

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

              mcp-server-time = {
                enabled = true;

                command = "${pkgs.mcp-server-time}/bin/mcp-server-time";
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

          opencode = {
            enable = true;
            package = pkgs.opencode-desktop;
            web.enable = false;

            enableMcpIntegration = true;

            mutableSettings = true;
            validateFiles = {
              config = false; # Not Applicable for pkgs.opencode-desktop
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
                protontricks
                umu-launcher
                vulkan-loader
                vulkan-tools
                winetricks
              ]
              ++ [
                config.home-manager.users.normal.programs.mangohud.package
                config.programs.gamemode.package
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

            font = fontPreferences.sansSerif;
            fontSize = pkgs.lib.toString (builtins.floor (designFactor * 1.5));
          };

          rofi.enable = false; # Manually Done Instead

          zed = {
            enable = config.home-manager.users.normal.programs.zed-editor.enable;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;

            icons = {
              enable = true;

              flavor = config.catppuccin.flavor;
            };

            italics = false;
          };

          opencode.enable = false; # Not Applicable for GUI

          mangohud = {
            enable = config.home-manager.users.normal.programs.mangohud.enable;

            flavor = config.catppuccin.flavor;
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
