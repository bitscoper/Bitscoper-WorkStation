# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.cockpit = {
      enable = true;
      package = (
        pkgs.cockpit.override {
          withBranding = true;
        }
      );
      plugins = with pkgs; [
        cockpit-files
        cockpit-zfs
      ];

      port = 9090;
      allowed-origins = [
        "*"
      ];

      showBanner = true;

      settings = {
        WebService = {
          AllowUnencrypted = false;

          LoginTo = true;
          AllowMultiHost = true;
        };
      };

      openFirewall = true;
    };

    security.pam.services.cockpit = {
      unixAuth = true;

      allowNullPassword = pkgs.lib.mkForce false;
      logFailures = true;
      nodelay = false;

      showMotd = true;
    };

    systemd.sockets.cockpit.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
  };
}
