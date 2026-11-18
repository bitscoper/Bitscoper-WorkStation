# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      wayscriber
    ];

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + A"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"wayscriber --no-tray --active\")")
            ];
          }
        ];
      }
    ];
  };
}
