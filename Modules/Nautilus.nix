# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  options.customOptions = {
    nameOfExecutableOfFileManager = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      internal = false;
      visible = true;
      readOnly = false;
      description = "Name of Executable of File Manager";
      default = "nautilus";
      example = "nautilus";
    };
  };

  config = {
    customOptions.nameOfExecutableOfFileManager = "nautilus";

    environment.systemPackages = with pkgs; [
      nautilus
      nautilus-python
    ];

    services.gnome.sushi.enable = true;

    programs = {
      nautilus-open-any-terminal = {
        enable = true;
        terminal = config.customOptions.nameOfExecutableOfTerminalEmulator;
      };

      dconf.profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "org/gnome/nautilus/icon-view" = {
              captions = [
                "size"
                "date_modified"
                "none"
              ];
            };

            "org/gtk/gtk4/settings/file-chooser" = {
              show-hidden = true;
            };
          };
        }
      ];
    };

    xdg.mime.defaultApplications = {
      "inode/directory" = "org.gnome.Nautilus.desktop";
      "inode/mount-point" = "org.gnome.Nautilus.desktop";
    };

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "XF86Explorer"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- org.gnome.Nautilus.desktop\")")
            ];
          }

          {
            _args = [
              "SUPER + F"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- org.gnome.Nautilus.desktop\")")
            ];
          }
        ];
      }
    ];
  };
}
