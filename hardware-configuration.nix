# By Abdullah As-Sadeed

# ASUS VivoBook X415EA 1.0 with the ELAN7001 SPI Touch Fingerprint Sensor and the 04F3:3128 I²C Touchpad

# for device in /sys/class/hidraw/hidraw*; do echo "== $device =="; readlink -f "$device/device"; cat "$device/device/uevent" 2>/dev/null || true; done

{
  lib,
  pkgs,
  ...
}:
{
  options = {
    specificHardwareConfiguration = {
      cpu = {
        architecture = lib.mkOption {
          type = lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "`\${nixpkgs.hostPlatform.system}-linux`";
          default = "";
          example = "";
        };

        vendor = lib.mkOption {
          type = lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "`hardware.cpu`";
          default = "";
          example = "";
        };
      };

      hardware = {
        graphics = {
          extraPackages = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            internal = false;
            visible = true;
            readOnly = false;
            description = "`hardware.graphics.extraPackages`";
            default = [ ];
            example = [ ];
          };

          extraPackages32 = lib.mkOption {
            type = lib.types.listOf lib.types.package;
            internal = false;
            visible = true;
            readOnly = false;
            description = "`hardware.graphics.extraPackages32`";
            default = [ ];
            example = [ ];
          };
        };
      };

      screen = {
        width = lib.mkOption {
          type = lib.types.int;
          internal = false;
          visible = true;
          readOnly = false;
          description = "";
          default = "";
          example = "";
        };

        height = lib.mkOption {
          type = lib.types.int;
          internal = false;
          visible = true;
          readOnly = false;
          description = "";
          default = "";
          example = "";
        };
      };

      boot = {
        extraModprobeConfig = lib.mkOption {
          type = lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "`boot.extraModprobeConfig`";
          default = [ ];
          example = [ ];
        };

        kernelParams = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "`boot.kernelParams`";
          default = [ ];
          example = [ ];
        };

        initrd = {
          availableKernelModules = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            internal = false;
            visible = true;
            readOnly = false;
            description = "`boot.initrd.availableKernelModules`";
            default = [ ];
            example = [ ];
          };
        };
      };

      kernelModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "`boot.kernelModules` and `boot.initrd.kernelModules`";
        default = [ ];
        example = [ ];
      };

      environment = {
        sessionVariables = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "`config.environment.sessionVariables`";
          default = [ ];
          example = [ ];
        };
      };

      systemd = {
        tmpfiles.rules = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "`systemd.tmpfiles.rules`";
          default = [ ];
          example = [ ];
        };
      };

      services = {
        udev = {
          extraRules = lib.mkOption {
            type = lib.types.str;
            internal = false;
            visible = true;
            readOnly = false;
            description = "`services.udev.extraRules`";
            default = [ ];
            example = [ ];
          };
        };

        fprintd = {
          tod = {
            enable = lib.mkOption {
              type = lib.types.bool;
              internal = false;
              visible = true;
              readOnly = false;
              description = "`services.fprintd.tod.enable`";
              default = [ ];
              example = [ ];
            };

            package = lib.mkOption {
              type = lib.types.package;
              internal = false;
              visible = true;
              readOnly = false;
              description = "`services.fprintd.tod.package`";
              default = [ ];
              example = [ ];
            };
          };
        };
      };
    };

    secrets = {
      password_1 = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Password 1";
        default = "";
        example = "";
      };

      password_2 = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Password 2";
        default = "";
        example = "";
      };
    };
  };

  config = {
    fileSystems = {
      "/" = {
        device = "/dev/mapper/luks-a5af0c70-392b-4dc5-9111-0f4b2864a698";
        fsType = "btrfs";

        options = [
          "async"
          "autodefrag"
          "compress=zstd:1"
          "discard=async"
          "noatime"
          "space_cache=v2"
          "ssd"
        ];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/B0AC-040A";
        fsType = "vfat";

        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      "/nix" = {
        device = "/dev/mapper/luks-a5af0c70-392b-4dc5-9111-0f4b2864a698";
        fsType = "btrfs";

        options = [
          "subvol=nix"
          "async"
          "autodefrag"
          "compress=zstd:1"
          "discard=async"
          "noatime"
          "space_cache=v2"
          "ssd"
        ];
      };

      "/home" = {
        device = "/dev/mapper/luks-a5af0c70-392b-4dc5-9111-0f4b2864a698";
        fsType = "btrfs";

        options = [
          "subvol=home"
          "async"
          "autodefrag"
          "compress=zstd:1"
          "discard=async"
          "noatime"
          "space_cache=v2"
          "ssd"
        ];
      };

      "/mnt/I_SATA_SSD" = {
        device = "/dev/disk/by-partlabel/I_SATA_SSD";
        fsType = "xfs";

        options = [
          "async"
          "defaults"
          "discard"
          # "discard=async"
          "inode64"
          "largeio"
          "noatime"
          "nofail"
          "swalloc"
        ];
      };
    }; # Mounts

    swapDevices = [
      {
        device = "/dev/mapper/luks-bb7b9c97-627f-420e-9388-5d047601b984";

        discardPolicy = "both";
      }
    ];

    boot = {
      initrd = {
        luks = {
          devices = {
            "luks-a5af0c70-392b-4dc5-9111-0f4b2864a698" = {
              device = "/dev/disk/by-uuid/a5af0c70-392b-4dc5-9111-0f4b2864a698";

              allowDiscards = true;
              bypassWorkqueues = true;
            };

            "luks-bb7b9c97-627f-420e-9388-5d047601b984" = {
              device = "/dev/disk/by-uuid/luks-bb7b9c97-627f-420e-9388-5d047601b984";

              allowDiscards = true;
              bypassWorkqueues = true;
            };
          };
        };
      };

      resumeDevice = "/dev/mapper/luks-bb7b9c97-627f-420e-9388-5d047601b984";
    };

    systemd = {
      services = {
        bind-elan7001-spi = {
          description = "Bind ELAN7001 SPI Fingerprint Sensor";

          wantedBy = [
            "multi-user.target"
          ];
          after = [
            "systemd-modules-load.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;

            ExecStart = "/bin/sh -c 'if [ -d /sys/bus/spi/devices/spi-ELAN7001:00 ]; then echo spidev > /sys/bus/spi/devices/spi-ELAN7001:00/driver_override && echo spi-ELAN7001:00 > /sys/bus/spi/drivers/spidev/bind; fi'";
          };
        };
      };
    };

    specificHardwareConfiguration = {
      cpu = {
        architecture = "x86_64";
        vendor = "intel";
      };

      hardware = {
        graphics = {
          extraPackages = with pkgs; [
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
      };

      screen = {
        width = 1980;
        height = 1080;
      };

      boot = {
        extraModprobeConfig = ''
          options kvm_intel nested=1
          options kvm_intel emulate_invalid_guest_state=0
          options spidev bufsiz=16642
        '';

        kernelParams = [
          "intel_iommu=on"
          "resume=/dev/mapper/luks-bb7b9c97-627f-420e-9388-5d047601b984"
        ];

        initrd = {
          availableKernelModules = [
            "ahci"
            "nvme"
            "rtsx_usb_sdmmc"
            "sd_mod"
          ];
        };
      };

      kernelModules = [
        "i915"
        "kvm-intel"
        "spi_pxa2xx_platform"
        "spidev"
      ];

      environment = {
        sessionVariables = {
          STEAM_COMPAT_MOUNTS = "/mnt/I_SATA_SSD:/run/current-system/sw/share/nix-ld/lib/";

          MESA_SHADER_CACHE_DIR = "/mnt/I_SATA_SSD/Games/Cache/Mesa_Shader/";
          DXVK_STATE_CACHE_PATH = "/mnt/I_SATA_SSD/Games/Cache/DXVK_State/";
          VKD3D_SHADER_CACHE_PATH = "/mnt/I_SATA_SSD/Games/Cache/VKD3D_Shader/";
        };
      };

      systemd = {
        tmpfiles.rules = [
          "d /mnt/I_SATA_SSD 0777 root root -"
        ];
      };

      services = {
        udev = {
          extraRules = "";
        };

        fprintd = {
          tod = {
            enable = false;
            package = pkgs.emptyDirectory;
          };
        };
      };
    };

    secrets = {
      password_1 = "*****************";
      password_2 = "*****************";
    };
  };
}
