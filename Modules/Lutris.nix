# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs = {
      nix-ld.libraries = with pkgs; [
        gamemode.lib
      ];

      gamemode = {
        enable = true;
        package = pkgs.gamemode;

        enableRenice = true;
      };
    };

    systemd.tmpfiles.rules = [
      "L+ /usr/bin/umu-run - - - - ${pkgs.umu-launcher}/bin/umu-run"
    ];

    services.udev.packages = with pkgs; [
      game-devices-udev-rules
    ];

    environment = {
      systemPackages =
        with pkgs;
        [
          gamepad-mirror
          jstest-gtk
          linuxConsoleTools
          protonup-qt
        ]
        ++ config.home-manager.users.normal.programs.lutris.extraPackages;

      sessionVariables = {
        WINE_DRIVER = "wayland";
        VKD3D_CONFIG = "vkd3d_shader_cache";
      };
    };

    home-manager.sharedModules = [
      {
        programs = {
          mangohud = {
            enable = true;
            package = pkgs.mangohud;
          };

          lutris = {
            enable = true;
            package = (
              pkgs.lutris.override {
                steamSupport = config.nixpkgs.config.allowUnfree;
              }
            );

            extraPackages =
              with pkgs;
              [
                protontricks
                umu-launcher
                vulkan-loader
                vulkan-tools
                winetricks
              ]
              ++ [
                config.home-manager.users.normal.programs.mangohud.package
                config.programs.gamemode.package
              ];
          };
        };

        catppuccin.mangohud = {
          enable = config.home-manager.users.normal.programs.mangohud.enable;

          flavor = config.catppuccin.flavor;
        };
      }
    ];

    users.users.normal.extraGroups = [
      "gamemode"
    ];
  };
}
