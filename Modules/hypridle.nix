# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        services.hypridle = {
          enable = true;
          package = pkgs.hypridle;

          settings = {
            general = {
              ignore_systemd_inhibit = false;
              ignore_wayland_inhibit = false;
              ignore_dbus_inhibit = false;

              lock_cmd = "pidof hyprlock || uwsm-app -- hyprlock";
            };

            listener = [
              {
                ignore_inhibit = false;

                timeout = 300; # 5 Minutes
                on-timeout = "loginctl lock-session";
              }
            ];
          };
        };
      }
    ];
  };
}
