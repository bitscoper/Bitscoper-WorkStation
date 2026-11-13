# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs = {
          keepassxc = {
            enable = true;
            package = (
              pkgs.keepassxc.override {
                withKeePassBrowser = true;
                withKeePassDocs = true;
                withKeePassFDOSecrets = true;
                withKeePassMinimal = false;
                withKeePassNetworking = true;
                withKeePassSSHAgent = !config.programs.gnupg.agent.enable;
                withKeePassX11 = config.programs.hyprland.xwayland.enable;
              }
            );
          };

          chromium.nativeMessagingHosts = [
            config.home-manager.users.normal.programs.keepassxc.package
          ];

          firefox.nativeMessagingHosts = [
            config.home-manager.users.normal.programs.keepassxc.package
          ];
        };

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + K"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- org.keepassxc.KeePassXC.desktop\")")
            ];
          }

          {
            _args = [
              "SUPER + CTRL + K"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"keepassxc --lock\")")
            ];
          }
        ];
      }
    ];

    programs.firefox.nativeMessagingHosts.packages = [
      config.home-manager.users.normal.programs.keepassxc.package
    ];
  };
}
