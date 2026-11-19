# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      (qbittorrent.override {
        guiSupport = true;
        trackerSearch = true;
        webuiSupport = true;
      })
    ];

    xdg.mime.defaultApplications = {
      "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
      "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";
    };
  };
}
