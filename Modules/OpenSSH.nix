# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    services.openssh = {
      enable = true;
      package = (
        pkgs.openssh.override {
          isNixos = true;
          linkOpenssl = true;
          withPAM = true;
        }
      );

      allowSFTP = true;

      listenAddresses = [
        {
          addr = "0.0.0.0";
        }
        {
          addr = "::";
        }
      ];
      ports = [
        22
      ];

      authorizedKeysInHomedir = true;

      settings =
        let
          banner = pkgs.writeText "opesshBanner.txt" "${config.networking.fqdn}";
        in
        {
          Banner = pkgs.lib.toString banner;
          LogLevel = "ERROR";
          PasswordAuthentication = true;
          PermitRootLogin = "yes";
          StrictModes = true;
          UseDns = true;
          X11Forwarding = config.programs.hyprland.xwayland.enable;
        };

      openFirewall = true;
    };

    security.pam.services.sshd = {
      unixAuth = true;

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

    programs.ssh = {
      package = config.services.openssh.package;
    };

    home-manager.sharedModules = [
      {
        programs.ssh = {
          enable = true;
          package = config.services.openssh.package;

          enableDefaultConfig = false;
        };
      }
    ];

    environment.systemPackages = with pkgs; [
      sshfs-fuse
    ];
  };
}
