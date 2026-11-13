# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.starship = {
      enable = true;
      package = pkgs.starship;

      interactiveOnly = true;

      presets = [
        "nerd-font-symbols"
      ];

      settings = {
        follow_symlinks = true;

        add_newline = false;
      };
    };

    home-manager.sharedModules = [
      {
        programs.starship = {
          enable = config.programs.starship.enable;
          package = config.programs.starship.package;

          enableBashIntegration = true;
          enableInteractive = config.programs.starship.interactiveOnly;

          presets = config.programs.starship.presets;
          settings = config.programs.starship.settings;
        };

        catppuccin.starship = {
          enable = config.programs.starship.enable;

          flavor = config.catppuccin.flavor;
        };
      }
    ];

  };
}
