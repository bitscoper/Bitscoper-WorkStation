# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    security = {
      polkit = {
        enable = true;
        package = (
          pkgs.polkit.override {
            useSystemd = true;
          }
        );
        enablePkexecWrapper = true;

        adminIdentities = [
          "unix-group:wheel"
        ];
      };

      soteria = {
        enable = true;
        package = pkgs.soteria;
      };

      pam.services.polkit-1 = {
        unixAuth = true;
        fprintAuth = true;

        rules.auth = {
          unix = {
            modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
            control = "sufficient";
            order = 1;
          };

          fprintd = {
            modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
            control = "sufficient";
            order = 2;
          };
        };

        allowNullPassword = pkgs.lib.mkForce false;
        logFailures = true;
        nodelay = false;

        enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;

        gnupg = {
          enable = config.home-manager.users.normal.programs.gpg.enable;
          storeOnly = false;
          noAutostart = false;
        };

        showMotd = true;
      };
    };
  };
}
