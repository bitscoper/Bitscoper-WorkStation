# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    hardware.bluetooth = {
      enable = true;
      package = (
        pkgs.bluez.override {
          enableExperimental = true;
        }
      );

      hsphfpd.enable = !config.services.pipewire.wireplumber.enable;

      powerOnBoot = true;

      input = {
        General = {
          IdleTimeout = 0; # 0 = Disabled
          LEAutoSecurity = true;
          ClassicBondedOnly = true;
          UserspaceHID = true;
        };
      };

      network = {
        General = {
          DisableSecurity = false;
        };
      };

      settings = {
        General = {
          MaxControllers = 0; # 0 = Unlimited
          ControllerMode = "dual";

          Name = config.networking.hostName;

          DiscoverableTimeout = 0; # 0 = Disabled
          PairableTimeout = 0; # 0 = Disabled
          AlwaysPairable = true;
          FastConnectable = true;

          ReverseServiceDiscovery = true;
          NameResolving = true;
          RemoteNameRequestRetryDelay = 60; # 60 Seconds
          RefreshDiscovery = true;
          TemporaryTimeout = 0; # 0 = Disabled

          SecureConnections = "on";
          Privacy = "off";

          Experimental = true; # Shows Battery Percentage
          KernelExperimental = true;
        };

        Policy = {
          AutoEnable = true;

          ResumeDelay = 2; # 2 Seconds
          ReconnectAttempts = 7;
          ReconnectIntervals = "1, 2, 4, 8, 16, 32, 64";
        };

        GATT = {
          Cache = "always";
        };

        CSIS = {
          Encryption = true;
        };

        AVRCP = {
          VolumeCategory = true;
          VolumeWithoutTarget = false;
        };

        AVDTP = {
          SessionMode = "ertm";
        };

        AdvMon = {
          RSSISamplingPeriod = "0x00";
        };
      };
    };

    services.pipewire.wireplumber.extraConfig.BlueZ = {
      "monitor.bluez.properties" = {
        "bluez5.enable-hw-volume" = true;

        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;

        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
          "hfp_ag"
          "hfp_hf"
          "hsp_ag"
          "hsp_hs"
        ];

        "bluez5.codecs" = [
          "aac"
          "aptx"
          "aptx_hd"
          "aptx_ll"
          "aptx_ll_duplex"
          "faststream"
          "faststream_duplex"
          "lc3"
          "lc3plus_h3"
          "ldac"
          "opus_05"
          "opus_05_51"
          "opus_05_71"
          "opus_05_duplex"
          "opus_05_pro"
          "sbc"
          "sbc_xq"
        ];
      };

      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };

    environment.systemPackages = with pkgs; [
      bluez-alsa
      bluez-tools
      overskride
    ];
  };
}
