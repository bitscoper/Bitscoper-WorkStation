# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
let
  currentTime = pkgs.lib.toString (builtins.currentTime);
in
{
  options = {
    customOptions.lutris = {
      hardwareSpecificPaths = {
        directoryOfLutrisPrefixes = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "Directory of Lutris Prefixes";
          default = "";
          example = "";
        };

        directoryOfInstalledGameFiles = pkgs.lib.mkOption {
          type = pkgs.lib.types.str;
          internal = false;
          visible = true;
          readOnly = false;
          description = "Directory of Installed Game Files";
          default = "";
          example = "";
        };
      };

      games = pkgs.lib.mkOption {
        type = pkgs.lib.types.listOf (
          pkgs.lib.types.submodule {
            options = {
              name = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Name of Game";
              };
              lutrisSlug = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Lutris Slug of Game";
              };
              lutrisConfigurationFileName = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Lutris Configuration File Name";
              };

              lutrisPrefixPath = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Lutris Prefix of Game";
              };
              executablePath = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Path of Game Executable";
              };
            };
          }
        );
        internal = false;
        visible = true;
        readOnly = false;
        description = "List of Games with Their Lutris Slugs";
        default = [
        ];
        example = [
          {
            name = "";
            lutrisSlug = "";
            lutrisConfigurationFileName = "";

            lutrisPrefixPath = "";
            executablePath = "";
          }

          {
            name = "";
            lutrisSlug = "";
            lutrisConfigurationFileName = "";

            lutrisPrefixPath = "";
            executablePath = "";
          }
        ];
      };
    };
  };

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

        xdg.dataFile = {
          "lutris/system.yml" = {
            enable = true;
            force = true;

            text = ''
              system:
                disable_runtime: true
                gamemode: true
                locale: en_US.utf8
                mangohud: true
            '';

            target = "lutris/system.yml";
            executable = false;
          };

          "lutris/runners/wine.yml" = {
            enable = true;
            force = true;

            text = ''
              wine:
                Graphics: wayland
                autoconf_joypad: true
                system_winetricks: true
            '';

            target = "lutris/runners/wine.yml";
            executable = false;
          };
        }
        // builtins.listToAttrs (
          map (game: {
            name = "lutris/games/${game.lutrisConfigurationFileName}.yml";

            value = {
              enable = true;
              force = true;

              text = ''
                game:
                  exe: ${builtins.toJSON game.executablePath}
                  prefix: ${builtins.toJSON game.lutrisPrefixPath}
              '';

              target = "lutris/games/${game.lutrisConfigurationFileName}.yml";
              executable = false;
            };
          }) config.customOptions.lutris.games
        );

        home.activation = {
          writeMutableLutrisConfFile = ''
            set -euo pipefail

            target="$HOME/.local/share/lutris/lutris.conf"

            mkdir -p "$(dirname "$target")"
            rm -f "$target"

            cat << 'EOF' > "$target"
            [services]
            xdg = True
            gog = False
            egs = False
            ea_app = False
            ubisoft = False
            steam = True

            [lutris]
            preferred_theme = dark
            show_advanced_options = True
            EOF

            chmod 0644 "$target"
          '';

          createMutableLutrisDatabaseFile =
            let
              sqlQuote = value: "'${builtins.replaceStrings [ "'" ] [ "''" ] value}'";

              insertionStatements = builtins.concatStringsSep "\n" (
                builtins.genList (
                  index:
                  let
                    game = builtins.elemAt config.customOptions.lutris.games index;
                  in
                  ''
                    INSERT INTO games VALUES (
                      ${pkgs.lib.toString (index + 1)},
                      ${sqlQuote game.name},
                      substr('x', 2, 0),
                      ${sqlQuote game.lutrisSlug},
                      NULL,
                      NULL,
                      'Windows',
                      'wine',
                      NULL,
                      substr('x', 2, 0),
                      NULL,
                      0,
                      1,
                      ${currentTime},
                      NULL,
                      ${sqlQuote game.lutrisConfigurationFileName},
                      0,
                      0,
                      0,
                      0,
                      NULL,
                      NULL,
                      NULL
                    );
                  ''
                ) (builtins.length config.customOptions.lutris.games)
              );
            in
            ''
              set -euo pipefail

              target="$HOME/.local/share/lutris/pga.db"

              mkdir -p "$(dirname "$target")"
              rm -f "$target"

              ${pkgs.sqlite}/bin/sqlite3 "$target" <<'SQL'

              PRAGMA foreign_keys=OFF;

              BEGIN TRANSACTION;

              CREATE TABLE games (
                id INTEGER PRIMARY KEY,
                name TEXT,
                sortname TEXT,
                slug TEXT,
                installer_slug TEXT,
                parent_slug TEXT,
                platform TEXT,
                runner TEXT,
                executable TEXT,
                directory TEXT,
                updated DATETIME,
                lastplayed INTEGER,
                installed INTEGER,
                installed_at INTEGER,
                year INTEGER,
                configpath TEXT,
                has_custom_banner INTEGER,
                has_custom_icon INTEGER,
                has_custom_coverart_big INTEGER,
                playtime REAL,
                service TEXT,
                service_id TEXT,
                discord_id TEXT
              );

              CREATE TABLE service_games (
                id INTEGER PRIMARY KEY,
                service TEXT,
                appid TEXT,
                name TEXT,
                slug TEXT,
                icon TEXT,
                logo TEXT,
                url TEXT,
                details TEXT,
                lutris_slug TEXT
              );

              CREATE TABLE sources (
                id INTEGER PRIMARY KEY,
                uri TEXT UNIQUE
              );

              CREATE TABLE categories (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE
              );

              CREATE TABLE games_categories (
                game_id INTEGER,
                category_id INTEGER
              );

              CREATE TABLE saved_searches (
                id INTEGER PRIMARY KEY,
                name TEXT UNIQUE,
                search TEXT
              );

              ${insertionStatements}

              COMMIT;

              SQL

              chmod 0644 "$target"
            '';
        };
      }
    ];

    users.users.normal.extraGroups = [
      "gamemode"
    ];

    customOptions.lutris.games = [
      rec {
        name = "Battlefield 3";
        lutrisSlug = "battlefield-3";
        lutrisConfigurationFileName = "${lutrisSlug}-${currentTime}";

        lutrisPrefixPath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Battlefield_3/";
        executablePath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Battlefield_3/bf3.exe";
      }

      rec {
        name = "Battlefield 4";
        lutrisSlug = "battlefield-4";
        lutrisConfigurationFileName = "${lutrisSlug}-${currentTime}";

        lutrisPrefixPath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Battlefield_4/";
        executablePath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Battlefield_4/bf4.exe";
      }

      rec {
        name = "Call of Duty 2";
        lutrisSlug = "call-of-duty-2";
        lutrisConfigurationFileName = "${lutrisSlug}-${currentTime}";

        lutrisPrefixPath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Call_of_Duty_2/";
        executablePath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Call_of_Duty_2/CoD2SP_s.exe";
      }

      rec {
        name = "Titanfall 2";
        lutrisSlug = "titanfall-2";
        lutrisConfigurationFileName = "${lutrisSlug}-${currentTime}";

        lutrisPrefixPath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Titanfall_2/";
        executablePath = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Titanfall_2/Titanfall2.exe";
      }
    ];
  };
}

# Preferences > "Lutris settings" > Updates > "Media updates" > "Download Missing Media"
