# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs.opencode = {
          enable = true;
          package = pkgs.opencode-desktop;
          web.enable = false;

          enableMcpIntegration = true;

          mutableSettings = true;
          validateFiles = {
            config = false; # Not Applicable for pkgs.opencode-desktop
          };
        };

        catppuccin.opencode.enable = false; # Not Applicable for GUI
      }
    ];
  };
}
