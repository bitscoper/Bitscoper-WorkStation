# By Abdullah As-Sadeed

{
  config,
  designFactor,
  fontPreferences,
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs.rofi = {
          enable = true;
          package = (
            pkgs.rofi.override {
              rofi-unwrapped = (
                pkgs.rofi-unwrapped.override {
                  waylandSupport = true;
                  x11Support = config.programs.hyprland.xwayland.enable;
                }
              );

              symlink-dmenu = true;
            }
          );

          settings = {
            modes = "run";

            font = "${fontPreferences.sansSerif} ${pkgs.lib.toString (builtins.floor (designFactor * 1.5))}";
            show-icons = false; # For dmenu
            icon-theme = config.home-manager.users.normal.gtk.iconTheme.name;

            global-kb = true;
            steal-focus = true;
            click-to-exit = true;
            hover-select = true;

            case-sensitive = false;
            fixed-num-lines = true;
            sort = true;
            cycle = true;

            disable-history = true;
            terminal = config.customOptions.nameOfExecutableOfTerminalEmulator;
          };

          theme =
            let
              makeLiteral = value: {
                _type = "literal";
                inherit value;
              };
            in
            {
              "*" = {
                # Catppuccin Mocha
                rosewater = makeLiteral "#f5e0dc";
                flamingo = makeLiteral "#f2cdcd";
                pink = makeLiteral "#f5c2e7";
                mauve = makeLiteral "#cba6f7";
                red = makeLiteral "#f38ba8";
                maroon = makeLiteral "#eba0ac";
                peach = makeLiteral "#fab387";
                yellow = makeLiteral "#f9e2af";
                green = makeLiteral "#a6e3a1";
                teal = makeLiteral "#94e2d5";
                sky = makeLiteral "#89dceb";
                sapphire = makeLiteral "#74c7ec";
                blue = makeLiteral "#89b4fa";
                lavender = makeLiteral "#b4befe";
                text = makeLiteral "#cdd6f4";
                subtext1 = makeLiteral "#bac2de";
                subtext0 = makeLiteral "#a6adc8";
                overlay2 = makeLiteral "#9399b2";
                overlay1 = makeLiteral "#7f849c";
                overlay0 = makeLiteral "#6c7086";
                surface2 = makeLiteral "#585b70";
                surface1 = makeLiteral "#45475a";
                surface0 = makeLiteral "#313244";
                base = makeLiteral "#1e1e2e";
                mantle = makeLiteral "#181825";
                crust = makeLiteral "#11111b";

                background-color = makeLiteral "@base";
                text-color = makeLiteral "@text";
              };

              window = {
                border = makeLiteral "1px";
                border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                border-color = makeLiteral "@surface2";
                padding = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
              };

              mainbox = {
                border = makeLiteral "0px";
                padding = makeLiteral "0px";
              };

              inputbar = {
                margin = makeLiteral "0px 0px ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px 0px";
                border = makeLiteral "1px";
                border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                border-color = makeLiteral "@surface2";
                background-color = makeLiteral "@mantle";
                padding = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                spacing = makeLiteral "0px";
                children = map makeLiteral [
                  "prompt"
                  "textbox-prompt-colon"
                  "entry"
                  "num-filtered-rows"
                  "textbox-num-sep"
                  "num-rows"
                  "case-indicator"
                ];
              };

              prompt = {
                background-color = makeLiteral "@mantle";
                spacing = makeLiteral "0px";
                text-color = makeLiteral "@lavender";
              };

              textbox-prompt-colon = {
                expand = false;
                margin = makeLiteral "0px 0.3000em 0.0000em 0.0000em";
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@lavender";
                str = ":";
              };

              entry = {
                background-color = makeLiteral "@mantle";
                spacing = makeLiteral "0px";
                placeholder-color = makeLiteral "@overlay0";
                placeholder = "Search";
                cursor = makeLiteral "text";
              };

              num-filtered-rows = {
                expand = false;
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@lavender";
              };

              textbox-num-sep = {
                expand = false;
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@lavender";
                str = "/";
              };

              num-rows = {
                expand = false;
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@lavender";
              };

              case-indicator = {
                background-color = makeLiteral "@mantle";
                spacing = makeLiteral "0px";
                text-color = makeLiteral "@lavender";
              };

              message = {
                margin = makeLiteral "0px 0px ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px 0px";
                border = makeLiteral "0px";
                padding = makeLiteral "0px";
              };

              textbox = {
                horizontal-align = makeLiteral "0.5";
                text-color = makeLiteral "@lavender";
              };

              listview = {
                fixed-height = makeLiteral "0px";
                border = makeLiteral "0px";
                scrollbar = true;
                padding = makeLiteral "0px";
                spacing = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
              };

              element = {
                border = makeLiteral "0px";
                border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px";
                padding = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                spacing = makeLiteral "0px";
                cursor = makeLiteral "pointer";
              };

              "element normal.normal" = {
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@text";
              };

              "element normal.urgent" = {
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@red";
              };

              "element normal.active" = {
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@blue";
              };

              "element alternate.normal" = {
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@text";
              };

              "element alternate.urgent" = {
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@red";
              };

              "element alternate.active" = {
                background-color = makeLiteral "@mantle";
                text-color = makeLiteral "@blue";
              };

              "element selected.normal" = {
                background-color = makeLiteral "@surface0";
                text-color = makeLiteral "@lavender";
              };

              "element selected.urgent" = {
                background-color = makeLiteral "@surface0";
                text-color = makeLiteral "@red";
              };

              "element selected.active" = {
                background-color = makeLiteral "@surface0";
                text-color = makeLiteral "@blue";
              };

              element-icon = {
                margin = makeLiteral "0px ${pkgs.lib.toString (builtins.floor designFactor)} 0px 0px";
                background-color = makeLiteral "transparent";
                size = makeLiteral "1.0000em";
                text-color = makeLiteral "inherit";
                cursor = makeLiteral "inherit";
              };

              element-text = {
                background-color = makeLiteral "transparent";
                text-color = makeLiteral "inherit";
                cursor = makeLiteral "inherit";
                highlight = makeLiteral "inherit";
              };

              scrollbar = {
                width = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                border = makeLiteral "1px";
                border-radius = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                border-color = makeLiteral "@surface1";
                background-color = makeLiteral "@mantle";
                padding = makeLiteral "0px";
                handle-width = makeLiteral "${pkgs.lib.toString (builtins.floor designFactor)}px";
                handle-color = makeLiteral "@lavender";
                cursor = makeLiteral "pointer";
              };
            };
        };

        catppuccin.rofi.enable = false; # Manually Done Instead

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + ALT + RETURN"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"cmd=$(compgen -c | sort -u | rofi -dmenu -sync -window-title 'Commands' -p 'Commands'); [ -n \\\"$cmd\\\" ] && uwsm-app -- ${config.customOptions.nameOfExecutableOfTerminalEmulator} bash -ic \\\"$cmd; bash -i\\\"\")")
            ];
          }
        ];
      }
    ];
  };
}
