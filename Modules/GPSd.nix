# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.gpsd = {
      enable = true;

      readonly = true;

      listenany = true;
      port = 2947;

      debugLevel = 0; # 0 = Disabled
    };

    systemd.services.gpsd.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start

    environment.systemPackages = with pkgs; [
      satellite
    ];

    users.users.normal.extraGroups = [
      "gpsd"
    ];
  };
}
