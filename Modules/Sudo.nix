# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    security = {
      sudo = {
        enable = true;
        package = (
          pkgs.sudo.override {
            withInsults = false;
          }
        );

        execWheelOnly = true;
        wheelNeedsPassword = true;

        extraConfig = ''
          Defaults pwfeedback
        '';
      };

      pam.services.sudo = {
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
