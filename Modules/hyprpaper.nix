# By Abdullah As-Sadeed

{
  pkgs,
  wallpaperFile,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        services.hyprpaper = {
          enable = true;
          package = pkgs.hyprpaper;

          settings = {
            ipc = "on";

            splash = false;

            wallpaper = {
              monitor = "";
              recursive = true;
              path = wallpaperFile;
              fit_mode = "cover";
            };
          };
        };
      }
    ];
  };
}
