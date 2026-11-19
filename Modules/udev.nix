# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    boot.kernelParams = [
      "rd.udev.log_level=err"
      "udev.log_level=err"
      "udev.log_priority=err"
    ];

    services.udev = {
      enable = true;
      packages = with pkgs; [
        libmtp.out
      ];

      extraRules = config.specificHardwareConfiguration.services.udev.extraRules;
    };

    environment.systemPackages = config.services.udev.packages;
  };
}
