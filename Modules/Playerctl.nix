# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      playerctl
    ];

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "XF86AudioPlay"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl play-pause\")")
              {
                locked = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioPause"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl play-pause\")")
              {
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86AudioStop"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl stop\")")
              {
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86AudioPrev"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl previous\")")
              {
                locked = true;
              }
            ];
          }

          {
            _args = [
              "XF86AudioNext"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"playerctl next\")")
              {
                locked = true;
              }
            ];
          }
        ];
      }
    ];
  };
}
