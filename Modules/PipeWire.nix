# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    services.pipewire = {
      enable = true;
      package = (
        pkgs.pipewire.override {
          bluezSupport = config.hardware.bluetooth.enable;
          enableSystemd = true;
          raopSupport = true;
          rocSupport = true;
          vulkanSupport = true;
          zeroconfSupport = true;
        }
      );

      # extraLadspaPackages = with pkgs; [
      # ];

      # extraLv2Packages = with pkgs; [
      # ];

      systemWide = false;

      audio.enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;

      socketActivation = true;

      wireplumber = {
        enable = true;
        package = (
          pkgs.wireplumber.override {
            enableDocs = true;
          }
        );

        extraLv2Packages = config.services.pipewire.extraLv2Packages;
      };

      raopOpenFirewall = true;
    };

    home-manager.sharedModules = [
      {
        services.easyeffects = {
          enable = true;
          package = pkgs.easyeffects;
        };
      }
    ];

    environment.systemPackages = with pkgs; [
      alsa-plugins
      alsa-utils
      helvum
      pwvucontrol
    ];

    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;

        settings = {
          "com/saivert/pwvucontrol" = {
            beep-on-volume-changes = true;
            enable-overamplification = true;
            use-peakmeter-led = false;
          };
        };
      }
    ];

    users.users.normal.extraGroups = [
      "audio"
      "pipewire"
    ];
  };
}
