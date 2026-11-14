# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.obs-studio = {
      enable = true;
      package = (
        pkgs.obs-studio.override {
          alsaSupport = true;
          browserSupport = false;
          pipewireSupport = true;
          pulseaudioSupport = true;
          scriptingSupport = true;
          withFdk = true;
        }
      );

      enableVirtualCamera = false; # Done Manually Instead

      plugins = with pkgs.obs-studio-plugins; [
        obs-3d-effect
        obs-backgroundremoval
        obs-composite-blur
        obs-gradient-source
        obs-gstreamer
        obs-multi-rtmp
        obs-mute-filter
        obs-pipewire-audio-capture
        obs-scale-to-sound
        obs-source-clone
        obs-source-record
        obs-text-pthread
        obs-transition-table
        obs-vaapi
        obs-vkcapture
      ];
    };

    home-manager.sharedModules = [
      {
        programs.obs-studio = {
          enable = config.programs.obs-studio.enable;
          package = config.programs.obs-studio.package;
          plugins = config.programs.obs-studio.plugins;
        };

        catppuccin.obs = {
          enable = config.programs.obs-studio.enable;

          flavor = config.catppuccin.flavor;
        }; # Settings > Appearance > Theme, Style
      }
    ];
  };
}
