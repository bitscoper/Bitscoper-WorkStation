# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs.gst_all_1; [
      (gstreamer.override {
        enableDocumentation = config.documentation.enable;
      })

      (gst-libav.override {
        enableDocumentation = config.documentation.enable;
      })

      (gst-plugins-bad.override {
        ajaSupport = true;
        bluezSupport = config.hardware.bluetooth.enable;
        enableDocumentation = config.documentation.enable;
        enableGplPlugins = true;
        enableZbar = true;
        guiSupport = true;
        ldacbtSupport = true;
        microdnsSupport = true;
        opencvSupport = true;
        openh264Support = true;
        webrtcAudioProcessingSupport = true;
      })

      (gst-plugins-base.override {
        enableAlsa = config.services.pipewire.alsa.enable;
        enableCdparanoia = true;
        enableDocumentation = config.documentation.enable;
        enableWayland = true;
      })

      (gst-plugins-good.override {
        enableDocumentation = config.documentation.enable;
        enableJack = true;
        enableWayland = true;
        gtkSupport = true;
        qt6Support = config.qt.enable;
      })

      (gst-plugins-ugly.override {
        enableDocumentation = config.documentation.enable;
        enableGplPlugins = true;
      })
    ];
  };
}
