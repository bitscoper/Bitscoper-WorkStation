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
      }
    ];

    boot = {
      initrd = {
        luks = {
          devices = {
            "luks-bd4924a7-a931-4592-890b-d7cc35be5e39" = {
              device = "/dev/disk/by-uuid/bd4924a7-a931-4592-890b-d7cc35be5e39";
            };

            "luks-34ec5350-db4d-46fb-b370-feefe9d3de0a" = {
              device = "/dev/disk/by-uuid/34ec5350-db4d-46fb-b370-feefe9d3de0a";
            };
          };
        };
      };

      resumeDevice = "/dev/mapper/luks-34ec5350-db4d-46fb-b370-feefe9d3de0a";
    };

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
        "resume=/dev/mapper/luks-34ec5350-db4d-46fb-b370-feefe9d3de0a"
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
