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
                default = "";
                example = "";
              };
              lutrisSlug = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Lutris Slug of Game";
                default = "";
                example = "";
              };
              nameOfLutrisConfigurationFile = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Name of Lutris Configuration File of Game";
                default = "";
                example = "";
              };

              environmentVariables = pkgs.lib.mkOption {
                type = pkgs.lib.types.attrsOf pkgs.lib.types.str;
                description = "Environment Variables For Game";
                default = { };
                example = { };
              };
              pathOfLutrisPrefix = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Path of Lutris Prefix of Game";
                default = "";
                example = "";
              };
              workingDirectory = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Working Directory of Game";
                default = "";
                example = "";
              };
              pathOfExecutable = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Path of Executable of Game";
                default = "";
                example = "";
              };
              arguments = pkgs.lib.mkOption {
                type = pkgs.lib.types.str;
                description = "Arguments to Executable of Game";
                default = "";
                example = "";
              };
            };
          }
        );
        internal = false;
        visible = true;
        readOnly = false;
        description = "Games";
        default = [
        ];
        example = [
          {
            name = "";
            lutrisSlug = "";
            nameOfLutrisConfigurationFile = "";

            environmentVariables = { };
            pathOfLutrisPrefix = "";
            workingDirectory = "";
            pathOfExecutable = "";
            arguments = "";
          }

          {
            name = "";
            lutrisSlug = "";
            nameOfLutrisConfigurationFile = "";

            environmentVariables = { };
            pathOfLutrisPrefix = "";
            workingDirectory = "";
            pathOfExecutable = "";
            arguments = "";
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
        __GL_SHADER_DISK_CACHE = 1;
        DXVK_HUD = "compiler";
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
            name = "lutris/games/${game.nameOfLutrisConfigurationFile}.yml";

            value = {
              enable = true;
              force = true;

              text =
                pkgs.lib.optionalString (game.environmentVariables != { }) (
                  "system:\n  env:\n"
                  + pkgs.lib.concatStringsSep "\n" (
                    pkgs.lib.mapAttrsToList (
                      name: value: "    ${name}: ${builtins.toJSON value}"
                    ) game.environmentVariables
                  )
                  + "\n"
                )
                + ''
                  game:
                    prefix: ${builtins.toJSON game.pathOfLutrisPrefix}
                    working_dir: ${builtins.toJSON game.workingDirectory}
                    exe: ${builtins.toJSON game.pathOfExecutable}
                    args: ${builtins.toJSON game.arguments}
                '';

              target = "lutris/games/${game.nameOfLutrisConfigurationFile}.yml";
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
                      ${sqlQuote game.nameOfLutrisConfigurationFile},
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

          downloadLutrisMedia = ''
              set -euo pipefail

              export PATH="${pkgs.coreutils-full}/bin:${pkgs.gnused}/bin:${pkgs.gnugrep}/bin:${pkgs.nix}/bin:''${PATH:-}"

              LUTRIS="${config.home-manager.users.normal.programs.lutris.package}"
              WRAPPER="${config.home-manager.users.normal.programs.lutris.package}/bin/lutris"

              PYTHON="${pkgs.python3Packages.python.interpreter}"

              if [[ ! -x "$WRAPPER" ]]; then
                exit 1
              fi

              if [[ ! -x "$PYTHON" ]]; then
                exit 1
              fi

              TMP="$(mktemp -d)"
              trap 'rm -rf "$TMP"' EXIT

              nix-store --query --requisites "$LUTRIS" \
                > "$TMP/store-closure"

              mapfile -t STORE_REFS < "$TMP/store-closure"

              PYTHON_TAG="$(
                "$PYTHON" -c \
                  'import sys; print("python%d.%d" % sys.version_info[:2])'
              )"

              INIT="$(
                sed -nE \
                  's/.*--symlink[[:space:]]+([^[:space:]]+)[[:space:]]+\/init.*/\1/p' \
                  "$WRAPPER" |
                  head -n1
              )"

              if [[ -z "$INIT" || ! -f "$INIT" ]]; then
                exit 1
              fi

              PYTHONPATH="/usr/lib64/$PYTHON_TAG/site-packages:/usr/lib/$PYTHON_TAG/site-packages"
              GI_TYPELIB_PATH="/usr/lib64/girepository-1.0:/usr/lib/girepository-1.0"

              for ref in "''${STORE_REFS[@]}"; do
                site="$ref/lib/$PYTHON_TAG/site-packages"

                if [[ -d "$site" ]]; then
                  PYTHONPATH="$PYTHONPATH:$site"
                fi

                typelib="$ref/lib/girepository-1.0"

                if [[ -d "$typelib" ]]; then
                  GI_TYPELIB_PATH="$GI_TYPELIB_PATH:$typelib"
                fi
              done

              cat > "$TMP/init" <<EOF
            #!/bin/sh

            export PYTHONNOUSERSITE=true
            export PYTHONPATH="$PYTHONPATH"
            export GI_TYPELIB_PATH="$GI_TYPELIB_PATH"

            "$PYTHON" - <<'PYTEST' || exit 1
            import gi
            from gi.repository import GLib
            PYTEST

            exec "$PYTHON" - <<'PYCODE'
            import os
            import requests
            from concurrent.futures import ThreadPoolExecutor

            from lutris import settings
            from lutris.database.games import get_games
            from lutris.util.http import download_file

            slugs = {
                game["slug"]
                for game in get_games()
                if game.get("slug")
            }

            if not slugs:
                raise SystemExit(0)

            paths = {
                "banners": settings.BANNER_PATH,
                "icons": settings.ICON_PATH,
                "covers": settings.COVERART_PATH,
            }

            for path in paths.values():
                os.makedirs(path, exist_ok=True)

            available = {
                "banners": {
                    f.rsplit(".", 1)[0]
                    for f in os.listdir(paths["banners"])
                },
                "icons": {
                    f.rsplit(".", 1)[0].replace("lutris_", "")
                    for f in os.listdir(paths["icons"])
                    if f.startswith("lutris_")
                },
                "covers": {
                    f.rsplit(".", 1)[0]
                    for f in os.listdir(paths["covers"])
                },
            }

            complete = (
                available["banners"]
                & available["icons"]
                & available["covers"]
            )

            missing = slugs - complete

            if not missing:
                raise SystemExit(0)

            url = settings.SITE_URL + "/api/games"
            games = []
            page = 1

            while True:
                response = requests.post(
                    url if page == 1 else f"{url}?page={page}",
                    json={
                        "games": list(missing),
                        "page": page,
                    },
                    timeout=60,
                )

                response.raise_for_status()
                data = response.json()

                games.extend(data.get("results", []))

                if not data.get("next"):
                    break

                page += 1

            downloads = []

            for game in games:
                slug = game["slug"]

                media = {
                    "banners": game.get("banner_url") or game.get("banner"),
                    "icons": game.get("icon_url") or game.get("icon"),
                    "covers": game.get("coverart"),
                }

                for kind, media_url in media.items():
                    if not media_url or slug in available[kind]:
                        continue

                    filename = (
                        f"lutris_{slug}.png"
                        if kind == "icons"
                        else f"{slug}.jpg"
                    )

                    destination = os.path.join(
                        paths[kind],
                        filename,
                    )

                    downloads.append(
                        (kind, slug, media_url, destination)
                    )

            def fetch(item):
                kind, slug, media_url, destination = item

                try:
                    return bool(
                        download_file(
                            media_url,
                            destination,
                            raise_errors=True,
                        )
                    )

                except Exception:
                    return False

            with ThreadPoolExecutor(max_workers=5) as executor:
                list(executor.map(fetch, downloads))

            PYCODE
            EOF

              chmod +x "$TMP/init"

              cp "$WRAPPER" "$TMP/lutris-wrapper"

              sed -i \
                "s|--symlink $INIT /init|--symlink $TMP/init /init|" \
                "$TMP/lutris-wrapper"

              if ! grep -Fq -- "--symlink $TMP/init /init" "$TMP/lutris-wrapper"; then
                exit 1
              fi

              "$TMP/lutris-wrapper"
          '';
        };
      }
    ];

    users.users.normal.extraGroups = [
      "gamemode"
    ];

    customOptions.lutris.games = [
      rec {
        name = "Battlefield 4";
        lutrisSlug = "battlefield-4";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Battlefield_4/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Battlefield_4/";
        pathOfExecutable = "${workingDirectory}bf4.exe";
      }

      rec {
        name = "Battlefield: Bad Company 2";
        lutrisSlug = "battlefield-bad-company-2";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Battlefield_Bad_Company_2/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Battlefield_Bad_Company_2/";
        pathOfExecutable = "${workingDirectory}BFBC2Game.exe";
      }

      rec {
        name = "Call of Duty 2";
        lutrisSlug = "call-of-duty-2";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Call_of_Duty_2/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Call_of_Duty_2/";
        pathOfExecutable = "${workingDirectory}CoD2SP_s.exe";
      }

      rec {
        name = "Call of Duty 4: Modern Warfare";
        lutrisSlug = "call-of-duty-4-modern-warfare";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Call_of_Duty_4_Modern_Warfare/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Call_of_Duty_4_Modern_Warfare/";
        pathOfExecutable = "${workingDirectory}iw3sp.exe";
      }

      rec {
        name = "Call of Duty: Modern Warfare 2";
        lutrisSlug = "call-of-duty-modern-warfare-2";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Call_of_Duty_Modern_Warfare_2/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Call_of_Duty_Modern_Warfare_2/";
        pathOfExecutable = "${workingDirectory}iw4sp.exe";
      }

      rec {
        name = "Call of Duty: World at War";
        lutrisSlug = "call-of-duty-world-at-war";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Call_of_Duty_World_at_War/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Call_of_Duty_World_at_War/";
        pathOfExecutable = "${workingDirectory}CoDWaW.exe";
      }

      rec {
        name = "Need for Speed: Hot Pursuit";
        lutrisSlug = "need-for-speed-hot-pursuit";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Need_for_Speed_Hot_Pursuit/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Need_for_Speed_Hot_Pursuit/";
        pathOfExecutable = "${workingDirectory}NFS11.exe";
      }

      rec {
        name = "Titanfall 2";
        lutrisSlug = "titanfall-2";
        nameOfLutrisConfigurationFile = "${lutrisSlug}-${currentTime}";

        pathOfLutrisPrefix = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfLutrisPrefixes}/Titanfall_2/";
        workingDirectory = "${config.customOptions.lutris.hardwareSpecificPaths.directoryOfInstalledGameFiles}/Titanfall_2/";
        pathOfExecutable = "${workingDirectory}Titanfall2.exe";
      }
    ];
  };
}
