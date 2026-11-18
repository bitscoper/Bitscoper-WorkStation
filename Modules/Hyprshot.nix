# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      hyprshot
    ];

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "Print"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=region --clipboard-only\")")
            ];
          }
          {
            _args = [
              "SHIFT + Print"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=window --clipboard-only\")")
            ];
          }
          {
            _args = [
              "ALT + Print"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=region\")")
            ];
          }
          {
            _args = [
              "SHIFT + ALT + Print"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- hyprshot --mode=window\")")
            ];
          }
        ];
      }
    ];
  };
}
