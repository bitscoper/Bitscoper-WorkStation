# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    networking.networkmanager = {
      enable = true;
      package = (
        pkgs.networkmanager.override {
          withSystemd = true;
        }
      );
      plugins = with pkgs; [
        networkmanager-l2tp
        networkmanager-openvpn
        networkmanager-ssh
      ];

      ethernet.macAddress = "permanent";

      wifi = {
        backend = "wpa_supplicant";

        powersave = false;

        scanRandMacAddress = true;
        macAddress = "permanent";
      };

      dhcp = "internal";
      dns = "systemd-resolved";

      logLevel = "WARN";
    };

    programs.nm-applet = {
      enable = true;
      package = pkgs.networkmanagerapplet;

      indicator = true;
    };

    home-manager.sharedModules = [
      {
        services.network-manager-applet = {
          enable = config.programs.nm-applet.enable;
          package = config.programs.nm-applet.package;
        };
      }
    ];

    environment.systemPackages = [
      config.programs.nm-applet.package # Also Provides nm-connection-editor
    ];

    users.users.normal.extraGroups = [
      "networkmanager"
      "nm-openvpn"
    ];
  };
}
