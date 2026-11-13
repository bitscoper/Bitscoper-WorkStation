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
  };
}
