# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      loupe
    ];

    xdg.mime.defaultApplications = {
      "image/*" = "org.gnome.Loupe.desktop";
    };
  };
}
