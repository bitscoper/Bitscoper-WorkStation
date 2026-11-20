# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.dbus = {
      enable = true;
      dbusPackage = (
        pkgs.dbus.override {
          enableSystemd = true;
        }
      );

      implementation = "broker";
    };

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings.on = {
          _args = [
            "hyprland.start"
            (pkgs.lib.generators.mkLuaInline ''
              function()
                hl.exec_cmd("dbus-update-activation-environment --systemd --all")
              end
            '')
          ];
        };
      }
    ];

    environment.systemPackages = with pkgs; [
      bustle
      d-spy
      dtui
    ];
  };
}
