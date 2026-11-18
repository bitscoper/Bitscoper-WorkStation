# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    time = {
      hardwareClockInLocalTime = false;

      timeZone = "Asia/Dhaka";
    };

    networking.timeServers = [
      "0.nixos.pool.ntp.org"
      "1.nixos.pool.ntp.org"
      "2.nixos.pool.ntp.org"
      "3.nixos.pool.ntp.org"
    ];

    services = {
      chrony = {
        enable = true;
        package = pkgs.chrony;

        enableMemoryLocking = true;

        servers = config.networking.timeServers;
        enableNTS = false;
        serverOption = "iburst";

        enableRTCTrimming = true;
        makestep = {
          enable = true;
        };
      };

      timesyncd.enable = !config.services.chrony.enable;
    };

    home-manager.sharedModules = [
      {
        programs.mcp.servers = {
          mcp-server-time = {
            enabled = true;

            command = "${pkgs.mcp-server-time}/bin/mcp-server-time";
          };
        };
      }
    ];
  };
}
