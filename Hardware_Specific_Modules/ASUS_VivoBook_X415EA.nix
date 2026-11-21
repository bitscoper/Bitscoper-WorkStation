# By Abdullah As-Sadeed

# ASUS VivoBook X415EA 1.0 with the ELAN7001 SPI Touch Fingerprint Sensor and the 04F3:3128 I²C Touchpad

# for device in /sys/class/hidraw/hidraw*; do echo "== $device =="; readlink -f "$device/device"; cat "$device/device/uevent" 2>/dev/null || true; done

{
  pkgs,
  ...
}:
{
  options = {
    customOptions.hardwareSpecificConfiguration.screen = {
      width = pkgs.lib.mkOption {
        type = pkgs.lib.types.int;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Width of Screen";
        default = "1920";
        example = "1920";
      };

      height = pkgs.lib.mkOption {
        type = pkgs.lib.types.int;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Height of Screen";
        default = "1080";
        example = "1080";
      };
    };
  };

  config = {
    customOptions.hardwareSpecificConfiguration.screen = {
      width = 1980;
      height = 1080;
    };

    nixpkgs.hostPlatform.system = "x86_64-linux";

    boot = {
      kernelModules = [
        "i915"
        "kvm-intel"
        "spi_pxa2xx_platform"
        "spidev"
      ];

      extraModprobeConfig = ''
        options kvm_intel emulate_invalid_guest_state=0
        options kvm_intel nested=1
        options snd-hda-intel model=alc256-asus-aio
        options spidev bufsiz=16642
      '';

      kernelParams = [
        "intel_iommu=on"
      ];

      initrd.availableKernelModules = [
        "ahci"
        "nvme"
        "rtsx_usb_sdmmc"
        "sd_mod"
      ];
    };

    hardware = {
      cpu = {
        intel = {
          updateMicrocode = true;
          microcodePackage = pkgs.microcode-intel;
        };
      };

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

    systemd.services.bind-elan7001-spi-fingerprint-sensor = {
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

    services.fprintd = {
      tod = {
        enable = false;
        driver = pkgs.emptyDirectory;
      };
    };
  };
}
