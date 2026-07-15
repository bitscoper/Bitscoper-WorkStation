# By Abdullah As-Sadeed

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

      availableKernelModules = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "`boot.initrd.availableKernelModules`";
        default = [ ];
        example = [ ];
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

      extraGraphicsPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        internal = false;
        visible = true;
        readOnly = false;
        description = "`hardware.graphics.extraPackages`";
        default = [ ];
        example = [ ];
      };

      extraGraphicsPackages32 = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        internal = false;
        visible = true;
        readOnly = false;
        description = "`hardware.graphics.extraPackages32`";
        default = [ ];
        example = [ ];
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
        example = "3x@mp13P@$$w0rd";
      };

      password_2 = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Password 2";
        default = "";
        example = "3x@mp13P@$$w0rd";
      };
    };
  };

  config = {
    fileSystems = {
      "/" = {
        device = "/dev/disk/by-uuid/270c24ad-9b83-45d6-a294-ce082f3c4061";
        fsType = "xfs";
      };

      "/boot" = {
        device = "/dev/disk/by-uuid/4236-838A";
        fsType = "vfat";
        options = [
          "fmask=0077"
          "dmask=0077"
        ];
      };
    };

    swapDevices = [
      {
        device = "/dev/disk/by-uuid/86f9b6f6-5129-42f4-b720-546e14ea511b";
      }
    ];

    specificHardwareConfiguration = {
      systemArchitecture = "x86_64";
      cpuVendor = "intel";

      availableKernelModules = [
        "ahci"
        "nvme"
        "rtsx_usb_sdmmc"
        "sd_mod"
      ];

      kernelModules = [
        "i915"
        "kvm-intel"
      ];

      extraModprobeConfig = ''
        options kvm_intel nested=1
      '';

      kernelParams = [
        "intel_iommu=on"
      ];

      extraGraphicsPackages = with pkgs; [
        # intel-ocl # FIXME: Build Failure
        intel-compute-runtime
        intel-gmmlib
        intel-media-driver
        libvpl
        vpl-gpu-rt
      ];

      extraGraphicsPackages32 = with pkgs.pkgsi686Linux; [
        intel-media-driver
      ];
    };

    secrets = {
      password_1 = "*****************";
      password_2 = "*****************";
    };
  };
}
