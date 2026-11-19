# By Abdullah As-Sadeed

{
  config,
  designFactor,
  fontPreferences,
  pkgs,
  ...
}:
{
  config = {
    gtk.iconCache.enable = true;

    catppuccin.gtk.icon.enable = false; # Done Manually Instead

    home-manager.sharedModules = [
      {
        gtk = {
          enable = true;

          font = {
            name = fontPreferences.sansSerif;
            package = pkgs.nerd-fonts.noto;
            size = builtins.floor (designFactor * 1.5);
          };

          colorScheme = "dark";
          theme = {
            name = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-standard+normal";
            package = (
              pkgs.catppuccin-gtk.override {
                accents = [
                  config.catppuccin.accent
                ];
                size = "standard";
                tweaks = [
                  "normal"
                ];
                variant = config.catppuccin.flavor;
              }
            );
          };

          iconTheme = {
            name = "Papirus-Dark";
            package = (
              pkgs.papirus-icon-theme.override {
                color = "black";
              }
            );
          };

          cursorTheme = {
            name = config.home-manager.users.normal.home.pointerCursor.name;
            package = config.home-manager.users.normal.home.pointerCursor.package;
            size = config.home-manager.users.normal.home.pointerCursor.size;
          };

          gtk4 = {
            enable = true;

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            colorScheme = config.home-manager.users.normal.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              package = config.home-manager.users.normal.gtk.cursorTheme.package;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };

          gtk3 = {
            enable = true;

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            colorScheme = config.home-manager.users.normal.gtk.colorScheme;
            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              package = config.home-manager.users.normal.gtk.cursorTheme.package;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };

          gtk2 = {
            enable = true;

            font = {
              name = config.home-manager.users.normal.gtk.font.name;
              package = config.home-manager.users.normal.gtk.font.package;
              size = config.home-manager.users.normal.gtk.font.size;
            };

            theme = {
              name = config.home-manager.users.normal.gtk.theme.name;
              package = config.home-manager.users.normal.gtk.theme.package;
            };

            iconTheme = {
              name = config.home-manager.users.normal.gtk.iconTheme.name;
              package = config.home-manager.users.normal.gtk.iconTheme.package;
            };

            cursorTheme = {
              name = config.home-manager.users.normal.gtk.cursorTheme.name;
              package = config.home-manager.users.normal.gtk.cursorTheme.package;
              size = config.home-manager.users.normal.gtk.cursorTheme.size;
            };
          };
        };

        catppuccin.gtk.icon.enable = config.catppuccin.gtk.icon.enable;
      }
    ];
  };
}
