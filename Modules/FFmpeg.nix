# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      ffpb

      (
        (ffmpeg-full.override {
          withAlsa = config.services.pipewire.alsa.enable;
          withAom = true;
          withAribb24 = true;
          withAribcaption = true;
          withAss = true;
          withAvisynth = true;
          withBluray = true;
          withBs2b = true;
          withBzlib = true;
          withCaca = true;
          withCdio = true;
          withCelt = true;
          withChromaprint = true;
          withCodec2 = true;
          withDav1d = true;
          withDavs2 = true;
          withDc1394 = true;
          withDrm = true;
          withDvdnav = true;
          withDvdread = true;
          withFlite = true;
          withFontconfig = true;
          withFreetype = true;
          withFrei0r = true;
          withFribidi = true;
          withGme = true;
          withGnutls = true;
          withGrayscale = true;
          withGsm = true;
          withHarfbuzz = true;
          withIconv = true;
          withIlbc = true;
          withJack = true;
          withJxl = true;
          withKvazaar = true;
          withLadspa = true;
          withLc3 = true;
          withLcevcdec = true;
          withLcms2 = true;
          withLzma = true;
          withModplug = true;
          withMp3lame = true;
          withMultithread = true;
          withMysofa = true;
          withNetwork = true;
          withOpenal = true;
          withOpencl = true;
          withOpencoreAmrnb = true;
          withOpencoreAmrwb = true;
          withOpengl = true;
          withOpenh264 = true;
          withOpenjpeg = true;
          withOpenmpt = true;
          withOpus = true;
          withPlacebo = true;
          withPulse = config.services.pipewire.pulse.enable;
          withQrencode = true;
          withQuirc = true;
          withRav1e = true;
          withRist = true;
          withRtmp = true;
          withRubberband = true;
          withSamba = true;
          withSdl2 = true;
          withShaderc = true;
          withShine = true;
          withSnappy = true;
          withSoxr = true;
          withSpeex = true;
          withSrt = true;
          withSsh = config.home-manager.users.normal.programs.ssh.enable;
          withSvg = true;
          withSvtav1 = true;
          withSwscaleAlpha = true;
          withTheora = true;
          withTwolame = true;
          withUavs3d = true;
          withUnfree = config.nixpkgs.config.allowUnfree;
          withV4l2 = true;
          withV4l2M2m = true;
          withVaapi = true;
          withVdpau = true;
          withVidStab = true;
          withVmaf = true;
          withVoAmrwbenc = true;
          withVorbis = true;
          withVpx = true;
          withVulkan = true;
          withVvenc = true;
          withWebp = true;
          withX264 = true;
          withX265 = true;
          withXavs = true;
          withXavs2 = true;
          withXevd = true;
          withXeve = true;
          withXml2 = true;
          withXvid = true;
          withZimg = true;
          withZlib = true;
          withZmq = true;
          withZvbi = true;
        }).overrideAttrs
          (_: {
            doCheck = false;
          })
      )
    ];
  };
}
