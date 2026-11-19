# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    services = {
      fprintd = {
        enable = true;
        package = if config.services.fprintd.tod.enable then pkgs.fprintd-tod else pkgs.fprintd;

        tod = {
          enable = config.specificHardwareConfiguration.services.fprintd.tod.enable;
          driver = pkgs.lib.optionals config.services.fprintd.tod.enable config.specificHardwareConfiguration.services.fprintd.tod.package;
        };
      };

      dbus.packages = with pkgs; [
        fprintd
      ];
    };
  };
}
