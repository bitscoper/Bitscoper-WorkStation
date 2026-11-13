# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.jellyfin = {
      enable = true;
      package = pkgs.jellyfin;

      forceEncodingConfig = true;

      transcoding = {
        h264Crf = true;
        h265Crf = true;

        enableSubtitleExtraction = true;
        enableToneMapping = false;

        enableHardwareEncoding = true;

        hardwareEncodingCodecs = {
          av1 = true;
          hevc = true;
        };

        hardwareDecodingCodecs = {
          av1 = true;
          h264 = true;
          hevc = true;
          hevc10bit = true;
          hevcRExt10bit = true;
          hevcRExt12bit = true;
          mpeg2 = true;
          vc1 = true;
          vp8 = true;
          vp9 = true;
        };

        deleteSegments = true;

        encodingPreset = "auto";
        throttleTranscoding = false;
        threadCount = null; # Null = Automatic Detection
        maxConcurrentStreams = null; # Null = Limited by Hardware
      };

      hardwareAcceleration = {
        enable = false;
        type = "vaapi";
      };

      user = "jellyfin";
      group = "jellyfin";

      openFirewall = true;
    };

    home-manager.sharedModules = [
      {
        home.activation.permitJellyfin = ''
          ${pkgs.acl}/bin/setfacl --modify user:jellyfin:--x $HOME
        '';
      }
    ];

    users.users.normal.extraGroups = [
      "jellyfin"
    ];
  };
}
