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
    programs = {
      hyprland = {
        enable = true;
        package = (
          pkgs.hyprland.override {
            debug = config.environment.enableDebugInfo;
            enableXWayland = config.programs.hyprland.xwayland.enable;
            withSystemd = true;
            wrapRuntimeDeps = true;
          }
        );
        portalPackage = pkgs.xdg-desktop-portal-hyprland;

        withUWSM = true;
        xwayland.enable = false;
      };

      xwayland.enable = config.programs.hyprland.xwayland.enable;
    };

    home-manager.sharedModules = [
      {
        wayland.windowManager.hyprland = {
          enable = config.programs.hyprland.enable;
          package = config.programs.hyprland.package;

          systemd = {
            enable = false;

            enableXdgAutostart = true;

            variables = [
              "--all"
            ];
          };

          xwayland.enable = config.programs.hyprland.xwayland.enable;

          configType = "lua";
          sourceFirst = true;

          settings = {
            monitor = [
              {
                output = ""; # "" = All
                mode = "highres";
                position = "auto";
                transform = 0;
                scale = 1.0;
              }
            ];

            bind = [
              {
                _args = [
                  "SUPER + 1"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 2"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"2\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 3"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"3\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 4"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"4\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 5"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"5\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 6"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"6\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 7"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"7\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 8"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"8\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 9"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"9\"})")
                ];
              }
              {
                _args = [
                  "SUPER + 0"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"10\"})")
                ];
              }
              {
                _args = [
                  "SUPER + mouse_up"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m-1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + mouse_down"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({workspace = \"m+1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + S"
                  (pkgs.lib.generators.mkLuaInline " hl.dsp.workspace.toggle_special(\"magic\")")
                ];
              }

              {
                _args = [
                  "SUPER + up"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"u\"})")
                ];
              }
              {
                _args = [
                  "SUPER + right"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"r\"})")
                ];
              }
              {
                _args = [
                  "SUPER + down"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"d\"})")
                ];
              }
              {
                _args = [
                  "SUPER + left"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.focus({direction = \"l\"})")
                ];
              }

              {
                _args = [
                  "SUPER + SHIFT + 1"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"1\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 2"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"2\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 3"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"3\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 4"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"4\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 5"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"5\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 6"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"6\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 7"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"7\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 8"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"8\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 9"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"9\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + 0"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"10\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + S"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"special:magic\"})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 1"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"1\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 2"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"2\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 3"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"3\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 4"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"4\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 5"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"5\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 6"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"6\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 7"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"7\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 8"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"8\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 9"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"9\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + 0"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"10\", follow=false})")
                ];
              }
              {
                _args = [
                  "SUPER + SHIFT + ALT + S"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.move({workspace = \"special:magic\", follow=false})")
                ];
              }

              {
                _args = [
                  "SUPER + mouse:272"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.drag()")
                  {
                    mouse = true;
                  }
                ];
              } # Left Button
              {
                _args = [
                  "SUPER + mouse:273"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.resize()")
                  {
                    mouse = true;
                  }
                ];
              } # Right Button
              {
                _args = [
                  "ALT + F11"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"maximized\"})")
                ];
              }
              {
                _args = [
                  "F11"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.fullscreen({mode = \"fullscreen\"})")
                ];
              }
              {
                _args = [
                  "SUPER + Q"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.close()")
                ];
              }
              {
                _args = [
                  "SUPER + ALT + Q"
                  (pkgs.lib.generators.mkLuaInline "hl.dsp.window.kill()")
                ];
              }
            ];

            config = {
              general = {
                allow_tearing = true;

                gaps_workspaces = 0;

                layout = "dwindle";

                gaps_in = builtins.floor (designFactor / 4.0);
                gaps_out = {
                  top = builtins.floor (designFactor / 2.0);
                  right = builtins.floor (designFactor / 2.0);
                  bottom = builtins.floor (designFactor / 2.0);
                  left = builtins.floor (designFactor / 2.0);
                };

                float_gaps = builtins.floor (designFactor / 2.0);

                border_size = 1;
                "col.inactive_border" = pkgs.lib.mkLuaInline "colors.surface1";
                "col.active_border" = pkgs.lib.mkLuaInline "colors.surface2";
                "col.nogroup_border" = pkgs.lib.mkLuaInline "colors.surface1";
                "col.nogroup_border_active" = pkgs.lib.mkLuaInline "colors.surface2";

                resize_on_border = true;
                hover_icon_on_border = true;

                no_focus_fallback = false;

                snap = {
                  enabled = true;

                  respect_gaps = true;
                  monitor_gap = builtins.floor (designFactor / 2.0);
                  window_gap = builtins.floor (designFactor / 2.0);

                  border_overlap = false;
                };

                modal_parent_blocking = true;

                locale = "en_US";
              };

              decoration = {
                shadow = {
                  enabled = true;

                  sharp = false;
                };

                border_part_of_window = true;
                rounding = builtins.floor designFactor;
                rounding_power = 4.0; # 4.0 = Squircle

                active_opacity = 1.0;
                fullscreen_opacity = 1.0;
                inactive_opacity = 1.0;

                dim_special = 0.25;
                dim_modal = true;
                dim_inactive = false;
                dim_strength = 0.0;

                blur = {
                  enabled = true;
                  new_optimizations = true;

                  special = true;
                  popups = true;
                  input_methods = true;

                  ignore_opacity = false;
                  xray = true;
                };

                glow = {
                  enabled = false;
                };
              };

              animations = {
                enabled = true;

                workspace_wraparound = false;
              };

              input = {
                numlock_by_default = false;
                kb_layout = "us";

                force_no_accel = false;
                scroll_button_lock = true;
                natural_scroll = false;
                left_handed = false;

                special_fallthrough = false;

                follow_mouse = 1; # 1 = Cursor movement will always change focus to the window under the cursor.
                focus_on_close = 1; # 1 = When a window is closed, focus will shift to the window under the cursor.
                mouse_refocus = true;

                touchpad = {
                  disable_while_typing = true;

                  flip_x = false;
                  flip_y = false;

                  middle_button_emulation = false;
                  clickfinger_behavior = false;

                  tap_to_click = true;

                  tap_and_drag = true;
                  drag_3fg = 1; # 1 = 3 Fingers
                  drag_lock = 2; # 2 = Enabled Sticky

                  natural_scroll = true;
                };

                touchdevice = {
                  enabled = true;
                };

                tablet = {
                  left_handed = false;
                };

                virtualkeyboard = {
                  release_pressed_on_close = true;
                };
              };

              gestures = {
                workspace_swipe_create_new = true;
                workspace_swipe_forever = true;

                # Touchpad
                workspace_swipe_invert = false;

                # Touchscreen
                workspace_swipe_touch = true;
                workspace_swipe_touch_invert = false;
              };

              group = {
                auto_group = false;

                merge_groups_on_drag = true;
                merge_groups_on_groupbar = true;

                group_on_movetoworkspace = false;
                merge_floated_into_tiled_on_groupbar = false;
                insert_after_current = true;
                focus_removed_window = true;

                groupbar = {
                  enabled = true;
                  stacked = false;

                  render_titles = true;
                  scrolling = true;
                  middle_click_close = false;

                  keep_upper_gap = true;
                  gradients = true;
                  blur = true;
                  round_only_edges = false;
                  gradient_round_only_edges = false;
                };
              };

              misc = {
                disable_watchdog_warning = false;
                disable_xdg_env_checks = false;
                disable_autoreload = false;
                disable_scale_notification = false;

                allow_session_lock_restore = true;
                session_lock_xray = false;

                key_press_enables_dpms = true;
                mouse_move_enables_dpms = true;
                vrr = 1; # 1 = On
                mouse_move_focuses_monitor = true;

                disable_splash_rendering = true;
                disable_hyprland_logo = true;

                close_special_on_empty = true;

                enable_swallow = true;

                name_vk_after_proc = true;
                enable_anr_dialog = true;

                exit_window_retains_fullscreen = false;

                focus_on_activate = true;

                always_follow_on_dnd = true;

                animate_mouse_windowdragging = true;
                animate_manual_resizes = true;

                middle_click_paste = true;

                font_family = fontPreferences.sansSerif;
              };

              layers = {
                layers_hog_keyboard_focus = true;
              };

              binds = {
                allow_workspace_cycles = false;
                workspace_back_and_forth = false;
                hide_special_on_workspace_change = false;

                window_direction_monitor_fallback = true;
                ignore_group_lock = false;
                movefocus_cycles_groupfirst = true;
                movefocus_cycles_fullscreen = false;
                allow_pin_fullscreen = true;

                disable_keybind_grabbing = true;
                pass_mouse_when_bound = false;
              };

              xwayland.enabled = config.programs.hyprland.xwayland.enable;

              render = {
                cm_enabled = true;
                cm_auto_hdr = 0; # 0 = Off
                send_content_type = true;
                new_render_scheduling = true;
                xp_mode = false;
                commit_timing_enabled = true;
              };

              cursor = {
                invisible = false;
                hide_on_key_press = false;
                hide_on_tablet = false;
                hide_on_touch = true;

                no_hardware_cursors = 2; # 2 = Automatic (Disabled When Tearing)
                enable_hyprcursor = true;
                sync_gsettings_theme = true;

                no_warps = false;
                persistent_warps = true;
                warp_back_after_non_mouse_input = true;

                zoom_rigid = true;
                zoom_detached_camera = false;
                zoom_disable_aa = false;
              };

              ecosystem = {
                enforce_permissions = false;

                no_update_news = false;
                no_donation_nag = false;
              };

              quirks = {
                prefer_hdr = 0; # 0 = Off
              };

              dwindle = {
                force_split = 0; # 0 = Split Follows Mouse
                use_active_for_splits = true;
                smart_split = false;
                preserve_split = true;

                smart_resizing = true;

                precise_mouse_move = true;
              };
            }; # Sorted from "General" to "Quirks" according to the "Configuring > Core > Config options" Page.

          };

          extraConfig = ''
            pcall(require, "monitors") -- Import if available.
          ''; # nwg-displays

          xdph.settings = {
            general = {
              toplevel_dynamic_bind = true;
            };

            screencopy = {
              allow_token_by_default = true;

              force_shm = false;
              cursor_mode = 2; # 2 = Embedded Mode # Lacks Support for 4 (Metadata Mode)
              max_fps = 0; # 0 = Unlimited
            };
          }; # xdg-desktop-portal-hyprland
        };

        catppuccin.hyprland = {
          enable = config.programs.hyprland.enable;

          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;
        };
      }
    ];

    environment.systemPackages = with pkgs; [
      hyprland-protocols
    ];
  };
}
