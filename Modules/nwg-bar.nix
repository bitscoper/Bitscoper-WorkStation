# By Abdullah As-Sadeed

{
  designFactor,
  fontPreferences,
  pkgs,
  transitionDuration,
  ...
}:
{
  config = {
    nixpkgs.overlays = [
      (final: previous: {
        nwg-bar = previous.nwg-bar.overrideAttrs (oldAttributes: {
          nativeBuildInputs =
            (oldAttributes.nativeBuildInputs or [
            ]
            )
            ++ (with previous; [
              python3
            ]);

          postPatch = (oldAttributes.postPatch or "") + ''
            python3 - <<'PY'
            from pathlib import Path

            path = Path("main.go")
            lines = path.read_text().splitlines(keepends=True)

            start = next(
              (
                i
                for i, line in enumerate(lines)
                if "createPixbuf(" in line and "b.Icon" in line
              ),
              None,
            )

            if start is None:
              raise SystemExit("Could not locate the icon-loading statement in main.go of nwg-bar!")

            end = next(
              (
                i
                for i in range(start + 1, len(lines))
                if "SetImage(img)" in lines[i]
              ),
              None,
            )

            if end is None:
              raise SystemExit("Could not locate SetImage(img) after the icon-loading statement of nwg-bar!")

            indent = lines[start][
              :len(lines[start]) - len(lines[start].lstrip())
            ]

            replacement = [
              indent + "var img *gtk.Image\n",
              indent + 'if strings.HasPrefix(b.Icon, "/") {\n',
              indent + "\tpixbuf, err := createPixbuf(b.Icon, *imgSize)\n",
              indent + "\tif err == nil {\n",
              indent + "\t\timg, _ = gtk.ImageNewFromPixbuf(pixbuf)\n",
              indent + "\t} else {\n",
              indent + '\t\timg, _ = gtk.ImageNewFromIconName("image-missing", gtk.ICON_SIZE_INVALID)\n',
              indent + "\t}\n",
              indent + "} else {\n",
              indent + "\timg, _ = gtk.ImageNewFromIconName(b.Icon, gtk.ICON_SIZE_DIALOG)\n",
              indent + "}\n",
              indent + "button.SetImage(img)\n",
            ]

            lines[start:end + 1] = replacement
            path.write_text("".join(lines))
            PY
          '';

          postInstall = (oldAttributes.postInstall or "") + ''
            for icon in system-lock-screen.svg system-log-out.svg system-shutdown.svg system-reboot.svg
            do
              file="$out/share/nwg-bar/images/$icon"

              if grep -q "fill:#ffffff" "$file"; then
                substituteInPlace "$file" --replace-fail "fill:#ffffff" "fill:currentColor"
              fi

              if grep -q "fill:#fff" "$file"; then
                substituteInPlace "$file" --replace-fail "fill:#fff" "fill:currentColor"
              fi
            done
          '';
        });
      }) # Enables currentColor
    ];

    environment.systemPackages = with pkgs; [
      nwg-bar
    ];

    home-manager.sharedModules = [
      {
        xdg.configFile = {
          "nwg-bar/bar.json" = {
            enable = true;

            source = pkgs.writeText "nwg-bar.json" ''
              [
                {
                  "label": "_Lock",
                  "exec": "loginctl lock-session",
                  "icon": "system-lock-screen-symbolic"
                },
                {
                  "label": "_Exit",
                  "exec": "uwsm stop",
                  "icon": "system-log-out-symbolic"
                },
                {
                  "label": "_Shutdown",
                  "exec": "systemctl -i poweroff",
                  "icon": "system-shutdown-symbolic"
                },
                {
                  "label": "_Reboot",
                  "exec": "systemctl reboot",
                  "icon": "system-reboot-symbolic"
                }
              ]
            ''; # FIXME: hyprshutdown Does Not Work

            target = "nwg-bar/bar.json";
            executable = null;
          };

          "nwg-bar/style.css" = {
            enable = true;

            source = pkgs.writeText "nwg-bar.css" ''
              /* Catppuccin Mocha */
              @define-color rosewater #f5e0dc;
              @define-color flamingo #f2cdcd;
              @define-color pink #f5c2e7;
              @define-color mauve #cba6f7;
              @define-color red #f38ba8;
              @define-color maroon #eba0ac;
              @define-color peach #fab387;
              @define-color yellow #f9e2af;
              @define-color green #a6e3a1;
              @define-color teal #94e2d5;
              @define-color sky #89dceb;
              @define-color sapphire #74c7ec;
              @define-color blue #89b4fa;
              @define-color lavender #b4befe;
              @define-color text #cdd6f4;
              @define-color subtext1 #bac2de;
              @define-color subtext0 #a6adc8;
              @define-color overlay2 #9399b2;
              @define-color overlay1 #7f849c;
              @define-color overlay0 #6c7086;
              @define-color surface2 #585b70;
              @define-color surface1 #45475a;
              @define-color surface0 #313244;
              @define-color base #1e1e2e;
              @define-color mantle #181825;
              @define-color crust #11111b;

              * {
                font-family: ${fontPreferences.sansSerif};
                font-size: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
              }

              window {
                border: 1px solid @surface2;
                border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
                /* background-color: @base; */
                background-color: rgba(30, 30, 46, 0.99);
              }

              button {
                margin: ${pkgs.lib.toString (builtins.floor designFactor)}px ${pkgs.lib.toString (builtins.floor designFactor)}px ${pkgs.lib.toString (builtins.floor designFactor)}px 0px;
                box-shadow: none;
                border: none;
                border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
                background-color: @mantle;
                padding-top: ${pkgs.lib.toString (builtins.floor designFactor)}px;
                padding-bottom: ${pkgs.lib.toString (builtins.floor (designFactor * 1.5))}px;
                color: @text;
                transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
              }

              button:first-child {
                margin-left: ${pkgs.lib.toString (builtins.floor designFactor)}px;
              }

              button:hover,
              button:focus {
                background-color: @surface0;
                color: @lavender;
              }

              button image {
                box-shadow: none;
                border: none;
                background-color: transparent;
                color: @text;
                transition: color ${pkgs.lib.toString transitionDuration}ms;
              }

              button:hover image,
              button:focus image {
                color: @lavender;
              }
            '';

            target = "nwg-bar/style.css";
            executable = null;
          };
        };

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + L"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-bar -p center -t 'bar.json' -s 'style.css'\")")
            ];
          }
        ];
      }
    ];
  };
}
