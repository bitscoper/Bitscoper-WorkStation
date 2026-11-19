# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      nocturne
    ];

    xdg.mime.defaultApplications = {
      "audio/*" = "com.jeffser.Nocturne.desktop";
    };
  };
}
