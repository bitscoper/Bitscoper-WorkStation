# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services = {
      btrfs.autoScrub = {
        enable = true;
        interval = "weekly";
      };

      beesd = { };
    };

    environment.systemPackages = with pkgs; [
      btrfs-assistant
      btrfs-heatmap
      btrfs-progs
    ];
  };
}
