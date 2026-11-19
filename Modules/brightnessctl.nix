# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      brightnessctl
    ];

    services.udev.extraRules = ''
      SUBSYSTEM=="backlight", ACTION=="add", KERNEL=="*", MODE="0666" RUN+="${pkgs.coreutils-full}/bin/chmod a+w /sys/class/backlight/%k/brightness"
    '';

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "XF86MonBrightnessUp"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl set 1%+\")")
              {
                repeating = true;
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86MonBrightnessDown"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"brightnessctl set 1%-\")")
              {
                repeating = true;
                locked = true;
              }
            ];
          }
        ];
      }
    ];
  };
}
