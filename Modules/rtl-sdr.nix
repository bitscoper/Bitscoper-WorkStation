# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    hardware.rtl-sdr = {
      enable = true;
      package = pkgs.rtl-sdr;
    };

    services.udev.packages = with pkgs; [
      rtl-sdr
    ];

    environment.systemPackages = with pkgs; [
      gnss-sdr
      gpredict
      rtl-sdr-librtlsdr
      sdrangel

      (sdrpp.override {
        airspy_source = true;
        airspyhf_source = true;
        audio_sink = true;
        bladerf_source = true;
        file_source = true;
        frequency_manager = true;
        hackrf_source = true;
        limesdr_source = true;
        m17_decoder = true;
        meteor_demodulator = true;
        network_sink = true;
        plutosdr_source = true;
        portaudio_sink = true;
        recorder = true;
        rfspace_source = true;
        rigctl_server = true;
        rtl_sdr_source = config.hardware.rtl-sdr.enable;
        rtl_tcp_source = true;
        scanner = true;
        soapy_source = true;
        spyserver_source = true;
        usrp_source = true;
      })
    ];
  };
}
