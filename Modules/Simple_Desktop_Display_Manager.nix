# By Abdullah As-Sadeed

{
  config,
  designFactor,
  fontPreferences,
  pkgs,
  wallpaperFile,
  ...
}:
{
  config = {
    services.displayManager = {
      enable = true;

      sddm = {
        enable = true;
        package = pkgs.qt6Packages.sddm;

        wayland = {
          enable = true;
          compositor = "kwin";
        };

        enableHidpi = true;

        autoNumlock = false;
        autoLogin.relogin = false;

        settings = {
          Wayland.SessionDir = "/etc/xdg/wayland-sessions/";
        };
      };

      defaultSession = "hyprland-uwsm";

      autoLogin.enable = false;

      logToJournal = true;
    };

    catppuccin.sddm = {
      enable = config.services.displayManager.sddm.enable;
      assertQt6Sddm = true;

      flavor = config.catppuccin.flavor;
      accent = config.catppuccin.accent;

      background = wallpaperFile;

      font = fontPreferences.sansSerif;
      fontSize = pkgs.lib.toString (builtins.floor (designFactor * 1.5));

      loginBackground = true;
      userIcon = true;

      clockEnabled = true;
    };

    systemd.tmpfiles.rules = [
      "r /run/current-system/sw/share/wayland-sessions/hyprland.desktop"
      "L+ /etc/xdg/wayland-sessions/hyprland-uwsm.desktop - - - - ${config.programs.hyprland.package}/share/wayland-sessions/hyprland-uwsm.desktop"
    ];

    security.pam.services.sddm = {
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
}
