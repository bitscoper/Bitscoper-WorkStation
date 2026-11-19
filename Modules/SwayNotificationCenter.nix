# By Abdullah As-Sadeed

{
  config,
  designFactor,
  fontPreferences,
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        services.swaync = {
          enable = true;
          package = pkgs.swaynotificationcenter;
        };

        catppuccin.swaync = {
          enable = config.home-manager.users.normal.services.swaync.enable;

          flavor = config.catppuccin.flavor;

          font = fontPreferences.sansSerif;
          fontSize = pkgs.lib.toString (builtins.floor (designFactor * 1.5));
        };
      }
    ];
  };
}
