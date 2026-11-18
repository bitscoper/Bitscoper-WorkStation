# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      cliphist
      wl-clipboard
    ];

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings = {
          on = {
            _args = [
              "hyprland.start"
              (pkgs.lib.generators.mkLuaInline ''
                function()
                  hl.exec_cmd("uwsm-app -- wl-paste --type text --watch cliphist store")
                  hl.exec_cmd("uwsm-app -- wl-paste --type image --watch cliphist store")
                end
              '')
            ];
          };

          bind = [
            {
              _args = [
                "SUPER + SPACE"
                (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"cliphist list | rofi -dmenu -sync -window-title 'Clipboard' -p 'Clipboard' | cliphist decode | wl-copy\")")
              ];
            }
          ];
        };
      }
    ];
  };
}
