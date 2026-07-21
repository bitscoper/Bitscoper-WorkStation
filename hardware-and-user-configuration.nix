# By Abdullah As-Sadeed

# ASUS VivoBook X415EA 1.0 with the ELAN7001 SPI Fingerprint Sensor and the 04F3:3128 I²C Touchpad

# for d in /sys/class/hidraw/hidraw*; do echo "== $d =="; readlink -f "$d/device"; cat "$d/device/uevent" 2>/dev/null || true; done

{
  config,
  lib,
  modulesPath,
  options,
  pkgs,
  ...
}:
{
  options = {
    specificHardwareConfiguration = {
      systemArchitecture = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "`\${nixpkgs.hostPlatform.system}-linux`";
        default = "";
        example = "";
      };

      cpuVendor = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "`hardware.cpu`";
        default = "";
        example = "";
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
        device = "/dev/mapper/luks-bd4924a7-a931-4592-890b-d7cc35be5e39";
        fsType = "btrfs";
        options = [
          "autodefrag"
          "compress=zstd:1"
          "discard=async"
          "noatime"
          "space_cache=v2"
          "ssd"
        ];
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/9A25-C94D";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };

      "/nix" = {
        device = "/dev/mapper/luks-bd4924a7-a931-4592-890b-d7cc35be5e39";
        fsType = "btrfs";
        options = [
          "subvol=nix"
          "compress=zstd:1"
          "noatime"
          "discard=async"
          "ssd"
          "space_cache=v2"
          "autodefrag"
        ];
      };

      "/home" = {
        device = "/dev/mapper/luks-bd4924a7-a931-4592-890b-d7cc35be5e39";
        fsType = "btrfs";
        options = [
          "subvol=home"
          "compress=zstd:1"
          "noatime"
          "discard=async"
          "ssd"
          "space_cache=v2"
          "autodefrag"
        ];
      };
    };

    swapDevices = [
      {
        device = "/dev/mapper/luks-34ec5350-db4d-46fb-b370-feefe9d3de0a";

        discardPolicy = "both";
      }
    ];

    boot = {
      initrd = {
        luks = {
          devices = {
            "luks-bd4924a7-a931-4592-890b-d7cc35be5e39" = {
              device = "/dev/disk/by-uuid/bd4924a7-a931-4592-890b-d7cc35be5e39";

              allowDiscards = true;
              bypassWorkqueues = true;
            };

            "luks-34ec5350-db4d-46fb-b370-feefe9d3de0a" = {
              device = "/dev/disk/by-uuid/34ec5350-db4d-46fb-b370-feefe9d3de0a";

              allowDiscards = true;
              bypassWorkqueues = true;
            };
          };
        };
      };

      resumeDevice = "/dev/mapper/luks-34ec5350-db4d-46fb-b370-feefe9d3de0a";
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
      systemArchitecture = "x86_64";
      cpuVendor = "intel";

      boot = {
        extraModprobeConfig = ''
          options kvm_intel nested=1
          options spidev bufsiz=16642
        '';

        kernelParams = [
          "intel_iommu=on"
          "resume=/dev/mapper/luks-34ec5350-db4d-46fb-b370-feefe9d3de0a"
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
