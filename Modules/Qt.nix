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
    qt = {
      enable = true;

      platformTheme = "qt5ct"; # Both qt6ct and qt5ct
      style = "kvantum";
    };

    home-manager.sharedModules = [
      {
        qt = {
          enable = config.qt.enable;

          platformTheme.name = "qtct";
          style.name = config.qt.style;

          qt6ctSettings = {
            Fonts = {
              fixed = "\"${fontPreferences.monospace},${
                pkgs.lib.toString (builtins.floor (designFactor * 1.5))
              },-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0\"";
              general = "\"${fontPreferences.sansSerif},${
                pkgs.lib.toString (builtins.floor (designFactor * 1.5))
              },-1,5,400,0,0,0,0,0,0,0,0,0,0,1,Regular,0,0\"";
            };

            Appearance = {
              custom_palette = true;
              color_scheme_path = "${config.catppuccin.sources.qt5ct}/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.conf";
              style = "kvantum-dark";

              icon_theme = config.home-manager.users.normal.gtk.iconTheme.name;

              standard_dialogs = "xdgdesktopportal";
            };

            Interface = {
              activate_item_on_single_click = 0; # 0 = Disabled
              buttonbox_layout = 2; # 2 = KDE
              dialog_buttons_have_icons = 0; # 0 = Disabled
              keyboard_scheme = 3; # 3 = KDE
              menus_have_icons = true;
              show_shortcuts_in_context_menus = true;
              toolbutton_style = 4; # 4 = Follow Application Style
              underline_shortcut = 2; # 2 = Enabled
            };
          };

          qt5ctSettings = {
            Appearance = {
              custom_palette = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.custom_palette;
              color_scheme_path = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.color_scheme_path;
              style = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.style;

              icon_theme = config.home-manager.users.normal.gtk.iconTheme.name;

              standard_dialogs = config.home-manager.users.normal.qt.qt6ctSettings.Appearance.standard_dialogs;
            };

            Interface = {
              activate_item_on_single_click =
                config.home-manager.users.normal.qt.qt6ctSettings.Interface.activate_item_on_single_click;
              buttonbox_layout = config.home-manager.users.normal.qt.qt6ctSettings.Interface.buttonbox_layout;
              dialog_buttons_have_icons =
                config.home-manager.users.normal.qt.qt6ctSettings.Interface.dialog_buttons_have_icons;
              keyboard_scheme = config.home-manager.users.normal.qt.qt6ctSettings.Interface.keyboard_scheme;
              menus_have_icons = config.home-manager.users.normal.qt.qt6ctSettings.Interface.menus_have_icons;
              show_shortcuts_in_context_menus =
                config.home-manager.users.normal.qt.qt6ctSettings.Interface.show_shortcuts_in_context_menus;
              toolbutton_style = config.home-manager.users.normal.qt.qt6ctSettings.Interface.toolbutton_style;
              underline_shortcut = config.home-manager.users.normal.qt.qt6ctSettings.Interface.underline_shortcut;
            };
          };

          kvantum = {
            enable = true;

            settings = {
              General = {
                theme = "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}";
              };
            };
          };
        };

        catppuccin = {
          qt5ct = {
            enable = config.catppuccin.enable;
            assertPlatformTheme = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };

          kvantum = {
            enable = config.home-manager.users.normal.qt.kvantum.enable;
            assertStyle = true;
            apply = true;

            flavor = config.catppuccin.flavor;
            accent = config.catppuccin.accent;
          };
        };
      }
    ];

    environment = {
      systemPackages = with pkgs; [
        hyprland-qt-support
      ];

      sessionVariables = {
        QT_QPA_PLATFORM = "wayland";
      };
    };
  };
}
