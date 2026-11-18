# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs.fastfetch = {
          enable = true;
          package = (
            pkgs.fastfetch.override {
              audioSupport = true;
              brightnessSupport = true;
              dbusSupport = true;
              enlightenmentSupport = !config.programs.hyprland.enable;
              flashfetchSupport = false;
              gnomeSupport = !config.programs.hyprland.enable;
              imageSupport = true;
              openclSupport = true;
              openglSupport = true;
              rpmSupport = false;
              sqliteSupport = true;
              terminalSupport = true;
              vulkanSupport = true;
              waylandSupport = true;
              x11Support = config.programs.hyprland.xwayland.enable;
              xfceSupport = !config.programs.hyprland.enable;
              zfsSupport = true;
            }
          );
        };
      }
    ];
  };
}
