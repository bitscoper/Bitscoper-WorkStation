# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs = {
          vivid = {
            enable = true;
            package = pkgs.vivid;

            enableBashIntegration = true;

            colorMode = "24-bit";
            activeTheme = "catppuccin-${config.catppuccin.flavor}";
          };

          dircolors.enable = !config.home-manager.users.normal.programs.vivid.enable;
        };

        catppuccin.vivid = {
          enable = config.catppuccin.enable;

          flavor = config.catppuccin.flavor;
        };
      }
    ];

    environment.extraInit = ''
      export LS_COLORS="$(${config.home-manager.users.normal.programs.vivid.package}/bin/vivid generate ${config.home-manager.users.normal.programs.vivid.activeTheme})"
    '';
  };
}
