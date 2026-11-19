# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.fwupd = {
      enable = true;
      package = (
        pkgs.fwupd.override {
          enablePassim = false;
        }
      );
    };

    systemd = {
      services.fwupd-refresh.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
      timers.fwupd-refresh.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
    };

    environment.systemPackages = with pkgs; [
      fwupd-efi
      gnome-firmware
    ];

    users.users.normal.extraGroups = [
      "fwupd-refresh"
    ];
  };
}
