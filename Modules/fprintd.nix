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
      };

      dbus.packages = with pkgs; [
        fprintd
      ];
    };
  };
}
