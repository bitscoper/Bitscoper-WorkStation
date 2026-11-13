# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    i18n.inputMethod = {
      enable = true;

      type = "fcitx5";
      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          fcitx5-openbangla-keyboard
        ];
        waylandFrontend = true;

        ignoreUserConfig = false;
      };

      enableGtk3 = true;
      enableGtk2 = false;
    };

    catppuccin.fcitx5 = {
      enable = config.catppuccin.enable;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;

      enableRounded = true;
    };

    home-manager.sharedModules = [
      {
        i18n.inputMethod = {
          enable = config.i18n.inputMethod.enable;

          type = config.i18n.inputMethod.type;
          fcitx5 = {
            addons = config.i18n.inputMethod.fcitx5.addons;
            waylandFrontend = config.i18n.inputMethod.fcitx5.waylandFrontend;

            systemd.enable = true;
            ignoreUserConfig = config.i18n.inputMethod.fcitx5.ignoreUserConfig;
          };
        };

        catppuccin.fcitx5 = {
          enable = config.catppuccin.fcitx5.enable;
          apply = true;

          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;

          enableRounded = true;
        };
      }
    ];
  };
}
