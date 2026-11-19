# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    hardware.i2c = {
      enable = true;

      group = "i2c";
    };

    environment.systemPackages = with pkgs; [
      i2c-tools
    ];

    users.users.normal.extraGroups = [
      "i2c"
    ];
  };
}
