# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    boot = {
      kernelParams = [
        "threadirqs"
      ];

      kernel.sysctl."vm.swappiness" = 10;
    };

    powerManagement.cpuFreqGovernor = "performance";

    hardware.firmware = with pkgs; [
      alsa-firmware
      sof-firmware
    ];

    services = {
      pipewire = {
        enable = true;
        package = (
          pkgs.pipewire.override {
            bluezSupport = config.hardware.bluetooth.enable;
            enableSystemd = true;
            raopSupport = true;
            rocSupport = true;
            vulkanSupport = true;
            zeroconfSupport = config.services.avahi.enable;
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

      udev.extraRules = ''
        KERNEL=="rtc0", GROUP="audio"
        KERNEL=="hpet", GROUP="audio"
        DEVPATH=="/devices/virtual/misc/cpu_dma_latency", OWNER="root", GROUP="audio", MODE="0660"
      '';
    };

    security.pam.loginLimits = [
      {
        domain = "@audio";
        item = "memlock";
        type = "-";
        value = "unlimited";
      }

      {
        domain = "@audio";
        item = "rtprio";
        type = "-";
        value = "99";
      }

      {
        domain = "@audio";
        item = "nofile";
        type = "soft";
        value = "524288"; # 524288 > 99999
      }

      {
        domain = "@audio";
        item = "nofile";
        type = "hard";
        value = "524288"; # 524288 > 99999
      }
    ];

    home-manager.sharedModules = [
      {
        services.easyeffects = {
          enable = true;
          package = pkgs.easyeffects;
        };

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "XF86AudioRaiseVolume"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+\")")
              {
                repeating = true;
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86AudioLowerVolume"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-\")")
              {
                repeating = true;
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86AudioMute"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle\")")
              {
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86AudioMicMute"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle\")")
              {
                locked = true;
              }
            ];
          }
        ];
      }
    ];

    environment.systemPackages = with pkgs; [
      alsa-plugins
      alsa-utils
      helvum
      millisecond
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
