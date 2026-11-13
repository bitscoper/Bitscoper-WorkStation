# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.bat = {
      enable = true;
      package = pkgs.bat;
      extraPackages = with pkgs.bat-extras; [
        batdiff
        batgrep
        batman
        batpipe
        batwatch
        prettybat
      ];
    };

    home-manager.sharedModules = [
      {
        programs.bat = {
          enable = config.programs.bat.enable;
          package = config.programs.bat.package;
          extraPackages = config.programs.bat.extraPackages;
        };

        catppuccin.bat = {
          enable = config.programs.bat.enable;

          flavor = config.catppuccin.flavor;
        };
      }
    ];

    environment.variables.PAGER = "bat";
  };
}
