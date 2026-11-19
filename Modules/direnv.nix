# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.direnv = {
      enable = true;
      package = pkgs.direnv;

      nix-direnv = {
        enable = true;
        package = pkgs.nix-direnv;
      };

      loadInNixShell = true;

      enableBashIntegration = true;

      silent = false;
    };

    home-manager.sharedModules = [
      {
        programs.direnv = {
          enable = config.programs.direnv.enable;
          package = config.programs.direnv.package;

          nix-direnv = {
            enable = config.programs.direnv.nix-direnv.enable;
            package = config.programs.direnv.nix-direnv.package;
          };

          enableBashIntegration = config.programs.direnv.enableBashIntegration;

          silent = config.programs.direnv.silent;
        };
      }
    ];
  };
}
