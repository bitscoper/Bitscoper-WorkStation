# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;

      disableTaildrop = false;

      port = 0; # 0 = Automatic
      openFirewall = true;
    };

    systemd.services.tailscaled.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
  };
}
