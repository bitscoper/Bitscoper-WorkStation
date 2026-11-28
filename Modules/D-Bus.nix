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

    customOptions.commandsOnStartOfHyprland = [
      "hl.exec_cmd(\"dbus-update-activation-environment --systemd --all\")"
    ];

    environment.systemPackages = with pkgs; [
      bustle
      d-spy
      dtui
    ];
  };
}
