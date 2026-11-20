# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    xdg = {
      sounds.enable = true;
      icons.enable = true;
      menus.enable = true;

      autostart.enable = true;

      portal = {
        enable = true;

        xdgOpenUsePortal = true;
      };

      mime = {
        enable = true;

        addedAssociations = config.xdg.mime.defaultApplications;
      };
    };

    home-manager.sharedModules = [
      {
        home.preferXdgDirectories = true;

        xdg = {
          portal = {
            enable = config.xdg.portal.enable;

            xdgOpenUsePortal = config.xdg.portal.xdgOpenUsePortal;
          };

          mime.enable = true;

          mimeApps = {
            enable = true;

            associations = {
              added = config.xdg.mime.addedAssociations;
              removed = config.xdg.mime.removedAssociations;
            };
            defaultApplications = config.xdg.mime.defaultApplications;
          };

          userDirs = {
            createDirectories = true;
            setSessionVariables = true;
          };

          configFile."mimeapps.list".force = true;
        };
      }
    ];

    environment.systemPackages = with pkgs; [
      xdg-user-dirs
      xdg-user-dirs-gtk
      xdg-utils
    ];
  };
}
