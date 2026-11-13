# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    programs.wireshark = {
      enable = true;
      package = (
        pkgs.wireshark.override {
          libpcap = (
            pkgs.libpcap.override {
              withBluez = true;
              withRdma = true;
              withRemote = true;
            }
          );
          withExtras = true;
          withQt = true;
        }
      );

      dumpcap.enable = true;
      usbmon.enable = true;
    };

    users.users.normal.extraGroups = [
      "wireshark"
    ];
  };
}
