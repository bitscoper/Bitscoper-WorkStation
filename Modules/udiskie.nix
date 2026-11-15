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
        services.udiskie = {
          enable = true;
          package = pkgs.udiskie;

          tray = "always";

          automount = true;
          notify = true;

          settings = {
            program_options = {
              menu = "nested";

              terminal = "uwsm-app -- ${config.customOptions.executableNameOfTerminalEmulator} ${config.customOptions.workingDirectoryFlagOfTerminalEmulator}";
              file_manager = "uwsm-app -- xdg-open";

              password_cache = 5; # 5 Minutes

            };

            quickmenu_actions = "all";
          };
        };
      }
    ];

    environment.systemPackages = [
      config.home-manager.users.normal.services.udiskie.package
    ];
  };
}
