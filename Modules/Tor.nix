# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      carburetor
      onionshare-gui

      (tor-browser.override {
        audioSupport = true;
        libnotifySupport = true;
        libvaSupport = true;
        mediaSupport = true;
        pipewireSupport = config.services.pipewire.enable;
        pulseaudioSupport = config.services.pipewire.pulse.enable;
        waylandSupport = true;
      })
    ];
  };
}
