# By Abdullah As-Sadeed

{
  pkgs,
  transitionDuration,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        services.syshud = {
          enable = true;
          package = pkgs.syshud;

          settings = {
            listeners = "keyboard,backlight,audio_in,audio_out";
            position = "bottom";
            orientation = "h";
            show-percentage = true;
            transition-time = transitionDuration;
            timeout = 2; # 2 Seconds
          };
        };
      }
    ];
  };
}
