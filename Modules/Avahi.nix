# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    services.avahi = {
      enable = true;
      package = (
        pkgs.avahi.override {
          gtk3Support = true;
        }
      );

      nssmdns4 = true;
      nssmdns6 = true;

      wideArea = false;

      settings = {
        server = {
          use-ipv4 = true;
          use-ipv6 = true;

          domain-name = config.networking.domain;
          host-name = config.networking.hostName;
        };

        publish = {
          disable-publishing = false;

          publish-domain = true;
          publish-addresses = true;
          publish-workstation = true;
          publish-hinfo = true;

          disable-user-service-publishing = false;
        };
      };

      openFirewall = true;
    };

    environment.systemPackages = with pkgs; [
      mdns-scanner
    ];

    users.users.normal.extraGroups = [
      "avahi"
    ];
  };
}
