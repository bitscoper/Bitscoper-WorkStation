# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      imhex
    ];

    home-manager.sharedModules = [
      {
        xdg.dataFile."imhex/themes/catppuccin-${config.catppuccin.flavor}.json" = {
          enable = true;
          force = true;

          source = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/catppuccin/imhex/refs/heads/main/themes/catppuccin-${config.catppuccin.flavor}.json";
          };

          target = "imhex/themes/catppuccin-${config.catppuccin.flavor}.json";
          executable = false;
        };
      }
    ];
  };
}
