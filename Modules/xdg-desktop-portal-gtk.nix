# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];

    home-manager.sharedModules = [
      {
        xdg.portal.extraPortals = config.xdg.portal.extraPortals;
      }
    ];

    environment = {
      systemPackages = config.xdg.portal.extraPortals;

      pathsToLink = [
        "/share/xdg-desktop-portal"
      ];
    };

    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;

        settings = {
          "org/gtk/settings/file-chooser" = {
            show-hidden = true;
            sort-directories-first = true;
          };
        };
      }
    ];
  };
}
