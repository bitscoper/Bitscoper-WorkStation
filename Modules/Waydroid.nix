# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    virtualisation.waydroid = {
      enable = true;
      package = (
        pkgs.waydroid-nftables.override {
          withNftables = true;
        }
      );
    };

    environment.systemPackages = with pkgs; [
      waydroid-helper
    ];

    systemd = {
      packages = with pkgs; [
        waydroid-helper
      ];

      services = {
        waydroid-container.wantedBy = pkgs.lib.mkForce [ ];
        waydroid-monitor.wantedBy = pkgs.lib.mkForce [ ];
        waydroid-mount.wantedBy = pkgs.lib.mkForce [ ];
      }; # No Automatic Start
    };
  };
}
