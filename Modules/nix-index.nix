# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.nix-index = {
      package = pkgs.nix-index;

      enableBashIntegration = true;
    };

    home-manager.sharedModules = [
      {
        programs.nix-index = {
          enable = config.programs.nix-index.enable;
          package = config.programs.nix-index.package;

          enableBashIntegration = config.programs.nix-index.enableBashIntegration;
        };
      }
    ];

    environment.systemPackages = [
      config.programs.nix-index.package
    ];
  };
}
