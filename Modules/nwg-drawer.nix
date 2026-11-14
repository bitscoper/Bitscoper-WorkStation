# By Abdullah As-Sadeed

{
  designFactor,
  fontPreferences,
  pkgs,
  transitionDuration,
  config,
  ...
}:
{
  config = {
    nixpkgs.overlays = [
      (final: previous: {
        nwg-drawer = previous.nwg-drawer.overrideAttrs (oldAttributes: {
          postPatch = (oldAttributes.postPatch or "") + ''
            substituteInPlace tools.go \
              --replace-fail 'exec.LookPath("uwsm")' 'exec.LookPath("uwsm-app")' \
              --replace-fail 'exec.Command("uwsm", append([]string{"app", "--"}, cParts...)...)' 'exec.Command("uwsm-app", append([]string{"--"}, cParts...)...)' \
              --replace-fail 'Unable to find uwsm, running command directly' 'Unable to find uwsm-app, running command directly'

            substituteInPlace main.go --replace-fail "or uwsm app -- (with 'uwsm' for Universal Wayland Session Manager) to launch programs" "or uwsm-app -- (with 'uwsm' for Universal Wayland Session Manager) to launch programs"
          '';
        });
      }) # Replaces Slower `uwsm app` with Faster `uwsm-app`
    ];

    environment.systemPackages = with pkgs; [
      nwg-drawer
    ];

    home-manager.sharedModules = [
      {
        xdg.configFile = {
          "nwg-drawer/style.css" = {
            enable = true;

            source = pkgs.writeText "nwg-drawer.css" ''
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
                background-color: @base;
                color: @text;
              }

              entry {
                margin-bottom: ${pkgs.lib.toString (builtins.floor (designFactor * 3.0))}px;
                border: 1px solid @surface2;
                background-color: @mantle;
              }

              #pinned-box {
                border-bottom: 1px solid @surface1;
                padding-bottom: ${pkgs.lib.toString (builtins.floor designFactor)}px;
              }

              button {
                box-shadow: none;
                border: none;
                background: none;
                transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
              }

              button:hover,
              button:focus {
                background: @surface0;
                color: @lavender;
              }

              image {
                box-shadow: none;
                border: none;
                background: none;
              }
            '';

            target = "nwg-drawer/style.css";
            executable = null;
          };
        };

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + RETURN"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- nwg-drawer -ovl -k -closebtn none -c 8 -spacing 24 -is 64 -g '${config.home-manager.users.normal.gtk.theme.name}' -i '${config.home-manager.users.normal.gtk.iconTheme.name}' -pbuseicontheme -s style.css -lang en -nocats -wm uwsm -term ${config.customOptions.executableNameOfTerminalEmulator} -nofs -fm ${config.customOptions.executableNameOfFileManager}\")")
            ];
          }
        ];
      }
    ];
  };
}
