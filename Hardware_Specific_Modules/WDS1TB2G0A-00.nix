# By Abdullah As-Sadeed

# WDS1TB2G0A-00

{
  ...
}:
{
  config = {
    fileSystems."/mnt/I_SATA_SSD" = {
      device = "/dev/disk/by-partlabel/I_SATA_SSD";
      fsType = "xfs";

      options = [
        "async"
        "defaults"
        "discard"
        "inode64"
        "largeio"
        "noatime"
        "nofail"
        "swalloc"
      ];
    };

    systemd.tmpfiles.rules = [
      "d /mnt/I_SATA_SSD 0777 root root -"
    ];

    customOptions.lutris.hardwareSpecificPaths = {
      directoryOfLutrisPrefixes = "/mnt/I_SATA_SSD/Games/Lutris_Prefixes";
      directoryOfInstalledGameFiles = "/mnt/I_SATA_SSD/Games/Installed_Game_Files";
    };

    environment.sessionVariables = {
      STEAM_COMPAT_MOUNTS = "/mnt/I_SATA_SSD:/run/current-system/sw/share/nix-ld/lib/";
      MESA_SHADER_CACHE_DIR = "/mnt/I_SATA_SSD/Games/Cache/Mesa_Shader/";
    };
  };
}
