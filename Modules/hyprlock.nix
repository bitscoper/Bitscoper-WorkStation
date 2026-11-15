# By Abdullah As-Sadeed

{
  config,
  designFactor,
  fontPreferences,
  pkgs,
  wallpaperFile,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs.hyprlock = {
          enable = true;
          package = pkgs.hyprlock;

          sourceFirst = true;

          settings = {
            general = {
              screencopy_mode = 0; # 0 = GPU Accelerated
              immediate_render = true;
              fractional_scaling = 2; # 2 = Automatic

              hide_cursor = false;

              ignore_empty_input = true;
              text_trim = false;
            };

            auth = {
              pam = {
                enabled = true;
                module = "hyprlock";
              };

              fingerprint = {
                enabled = true;

                ready_message = "Scan Fingerprint";
                present_message = "Scanning Fingerprint";
              };
            };

            animations = {
              enabled = true;
            };

            background = [
              {
                monitor = ""; # "" = All
                path = wallpaperFile;
              }
            ];

            label = [
              {
                monitor = ""; # "" = All
                halign = "center";
                valign = "top";
                position = "0, -${
                  pkgs.lib.toString (builtins.floor (config.specificHardwareConfiguration.screen.height * 0.10))
                }";

                text_align = "center";
                font_family = fontPreferences.sansSerif;
                font_size = builtins.floor (designFactor * 8.0);
                color = "\$text";
                text = "\$TIME12";
              }

              {
                monitor = ""; # "" = All
                halign = "center";
                valign = "bottom";
                position = "0, ${
                  pkgs.lib.toString (builtins.floor (config.specificHardwareConfiguration.screen.height * 0.04))
                }";

                text_align = "center";
                font_family = fontPreferences.sansSerif;
                font_size = builtins.floor (designFactor * 1.5);
                color = "\$lavender";
                text = "\$FPRINTPROMPT";
              }
            ];

            input-field = [
              {
                monitor = ""; # "" = All
                halign = "center";
                valign = "bottom";
                position = "0, ${
                  pkgs.lib.toString (builtins.floor (config.specificHardwareConfiguration.screen.height * 0.10))
                }";

                size = "${pkgs.lib.toString (builtins.floor (designFactor * 42.0))}, ${
                  pkgs.lib.toString (builtins.floor (designFactor * 6.0))
                }";
                rounding = builtins.floor (designFactor * 2.0);
                outline_thickness = 1;
                outer_color = "\$surface2";
                shadow_passes = 0; # 0 = Disabled

                inner_color = "\$mantle";

                hide_input = false;
                font_family = fontPreferences.sansSerif;
                font_color = "\$lavender";
                placeholder_text = "Enter Password for $DESC";
                dots_center = true;
                dots_rounding = -1;

                fade_on_empty = true;

                invert_numlock = false;
                capslock_color = "\$mauve";
                numlock_color = "\$mauve";
                bothlock_color = "\$mauve";

                check_color = "\$blue";
                fail_color = "\$red";
                fail_text = "$FAIL <b>($ATTEMPTS)</b>";
              }
            ];
          };
        };

        catppuccin.hyprlock = {
          enable = config.home-manager.users.normal.programs.hyprlock.enable;

          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;

          useDefaultConfig = false;
        };
      }
    ];

    security.pam.services.hyprlock = {
      unixAuth = true;
      fprintAuth = true;

      rules.auth = {
        unix = {
          modulePath = "${pkgs.pam}/lib/security/pam_unix.so";
          control = "sufficient";
          order = 1;
        };

        fprintd = {
          modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
          control = "sufficient";
          order = 2;
        };
      };

      allowNullPassword = pkgs.lib.mkForce false;
      logFailures = true;
      nodelay = false;

      enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;

      gnupg = {
        enable = config.home-manager.users.normal.programs.gpg.enable;
        storeOnly = false;
        noAutostart = false;
      };

      showMotd = true;
    };
  };
}
