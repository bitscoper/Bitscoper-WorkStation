# By Abdullah As-Sadeed

# SDDPNQD-512G-1102

{
  ...
}:
{
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
    };

    swapDevices = [
      {
        device = "/dev/mapper/luks-bb7b9c97-627f-420e-9388-5d047601b984";

        discardPolicy = "both";
      }
    ];

    boot = {
      initrd.luks.devices = {
        "luks-a5af0c70-392b-4dc5-9111-0f4b2864a698" = {
          device = "/dev/disk/by-uuid/a5af0c70-392b-4dc5-9111-0f4b2864a698";

          allowDiscards = true;
          bypassWorkqueues = true;
        };

        "luks-bb7b9c97-627f-420e-9388-5d047601b984" = {
          device = "/dev/disk/by-uuid/bb7b9c97-627f-420e-9388-5d047601b984";

          allowDiscards = true;
          bypassWorkqueues = true;
        };
      };

      resumeDevice = "/dev/mapper/luks-bb7b9c97-627f-420e-9388-5d047601b984";
    };
  };
}
