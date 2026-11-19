# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.wayvnc = {
      enable = true;
      package = pkgs.wayvnc;
    };

    home-manager.sharedModules = [
      {
        services.wayvnc = {
          enable = config.programs.wayvnc.enable;
          package = config.programs.wayvnc.package;

          settings = {
            address = "0.0.0.0"; # Not to be Allowed through Firewall
            port = 5901;
          };

          autoStart = false; # No Automatic Start
        };
      }
    ];
  };
}
