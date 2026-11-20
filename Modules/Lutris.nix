# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    boot = {
      kernelParams = [
        "split_lock_detect=off"
      ];

      kernel.sysctl = {
        "kernel.split_lock_mitigate" = 0;
        "vm.max_map_count" = 2147483642;
      };
    };

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

    systemd = {
      tmpfiles.rules = [
        "L+ /usr/bin/umu-run - - - - ${pkgs.umu-launcher}/bin/umu-run"
      ];

      settings.Manager.DefaultLimitNOFILE = 524288; # Esync
    };

    security.pam.loginLimits = [
      {
        domain = config.users.users.normal.name;
        item = "nofile";
        type = "soft";
        value = "524288";
      } # Esync

      {
        domain = config.users.users.normal.name;
        item = "nofile";
        type = "hard";
        value = "524288";
      } # Esync
    ];

    services.udev.packages = with pkgs; [
      game-devices-udev-rules
    ];

    environment = {
      systemPackages =
        with pkgs;
        [
          evtest
          evtest-qt
          gamepad-tool
          linuxConsoleTools
          protonup-qt
        ]
        ++ config.home-manager.users.normal.programs.lutris.extraPackages;

      sessionVariables = {
        WINE_DRIVER = "wayland";
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
