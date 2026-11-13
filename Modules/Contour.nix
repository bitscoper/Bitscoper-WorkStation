# By Abdullah As-Sadeed

{
  designFactor,
  fontPreferences,
  pkgs,
  transitionDuration,
  ...
}:
{
  options.customOptions = {
    executableNameOfTerminalEmulator = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      internal = false;
      visible = true;
      readOnly = false;
      description = "Executable Name of Terminal Emulator";
      default = "contour";
      example = "contour";
    };

    workingDirectoryFlagOfTerminalEmulator = pkgs.lib.mkOption {
      type = pkgs.lib.types.str;
      internal = false;
      visible = true;
      readOnly = false;
      description = "Working Directory Flag of Terminal Emulator";
      default = "working-directory";
      example = "working-directory";
    };
  };

  config = {
    customOptions = {
      executableNameOfTerminalEmulator = "contour";
      workingDirectoryFlagOfTerminalEmulator = "working-directory";
    };

    nixpkgs.overlays = [
      (final: previous: {
        contour = previous.contour.overrideAttrs (oldAttributes: {
          postPatch = (oldAttributes.postPatch or "") + ''
            substituteInPlace src/contour/qml/TerminalPane.qml --replace-fail 'border.color: "#3daee9"' 'border.color: "#1e1e2e"'
          '';
        });
      }) # Blends the Hardcoded Border Color of Active Pane with the Background Color (Base of Catppuccin Mocha) to Hide
    ];

    environment.systemPackages = with pkgs; [
      contour
    ];

    home-manager.sharedModules = [
      {
        xdg.configFile = {
          "contour/contour.yml" = {
            enable = true;

            source = pkgs.writeText "contour.yml" ''
              platform_plugin: auto
              renderer:
                backend: vulkan

              spawn_new_process: true
              remember_window_position: false

              gui_config_locked: false
              live: true

              ui_style: native
              window_control_style: auto
              tab_bar_visibility: Multiple
              tab_bar_position: Top
              tab_switch_on_horizontal_wheel: true
              chrome_density: comfortable
              theme: terminal
              command_palette_recent_count: 0
              gutter:
                line_numbers: off
                timestamps: false
                user_marks: false
                exit_status: false
                bold_on_hover: false
              folding:
                enabled: false
                show_markers: false
                auto_collapse_on_new_command: false
              git_drawings:
                branch_style: thin
                arc_style: round
                merge_commit_style: bullet
              box_arc_style: round

              daemon:
                mode: in_process
              connect_picker_on_start: false
              osc_context:
                enabled: true

              images:
                good_image_protocol: true
                sixel_scrolling: true

              grapheme_clustering: true
              reflow_on_resize: true
              snap_to_rows: false
              text_scaling_method: rerasterize

              hyperlink_hover_tooltip: true
              on_mouse_selection: CopyToSelectionClipboard
              secure_input: auto

              accessibility_announcements: true
              accessibility_caret_reporting: true

              ui_font_family: ${fontPreferences.sansSerif}

              color_schemes:
                catppuccin_mocha:
                  default:
                    background: "#1e1e2e" # Base
                    foreground: "#cdd6f4" # Text

                  cursor:
                    default: "#f5e0dc" # Rosewater
                    text: "#1e1e2e" # Base

                  normal:
                    black: "#45475a" # Surface 1
                    red: "#f38ba8" # Red
                    green: "#a6e3a1" # Green
                    yellow: "#f9e2af" # Yellow
                    blue: "#89b4fa" # Blue
                    magenta: "#f5c2e7" # Pink
                    cyan: "#94e2d5" # Teal
                    white: "#bac2de" # Subtext 1

                  bright:
                    black: "#585b70" # Surface 2
                    red: "#f38ba8" # Red
                    green: "#a6e3a1" # Green
                    yellow: "#f9e2af" # Yellow
                    blue: "#89b4fa" # Blue
                    magenta: "#f5c2e7" # Pink
                    cyan: "#94e2d5" # Teal
                    white: "#a6adc8" # Subtext 0

              profiles:
                main:
                  pixel_reporting: Device

                  size_indicator_on_resize: true
                  margins:
                    horizontal: ${pkgs.lib.toString (builtins.floor designFactor)}
                    vertical: ${pkgs.lib.toString (builtins.floor designFactor)}
                  show_title_bar: true
                  status_line:
                    display: none
                    position: Bottom
                  scrollbar:
                    position: Right
                    mode: always
                    hide_in_alt_screen: false
                    marks: [failures, commands, running, user_marks, search_matches]
                  sticky_header:
                    mode: scrolled

                  mouse:
                    hide_while_typing: false
                  mouse_forwarding: forwarded
                  input_method_editor: true
                  input_method_editor_style: highlighted
                  cursor:
                    shape: bar
                    blinking: true
                  cursor_motion_animation_duration: ${
                    pkgs.lib.toString (builtins.floor (transitionDuration / 2.0))
                  }
                  blink_style: smooth

                  history:
                    auto_scroll_on_update: false
                  smooth_scrolling: true
                  momentum_scrolling: true

                  screen_transition_style: fade
                  screen_transition_duration: ${pkgs.lib.toString transitionDuration}

                  link_detection:
                    primary_screen:
                      file_paths: true
                      urls: true
                    other_screens:
                      file_paths: true
                      urls: true
                  hyperlink_decoration:
                    mode: hover
                    hover: underline

                  highlight_word_and_matches_on_double_click: true
                  search_case_sensitivity: smart
                  copy_command_preserve_multiline: true

                  bell:
                    sound: "default"
                    volume: 1 # 1 = Maximum
                    alert: true

                  notify_on_command_finish:
                    when: unfocused
                    outcome: any
                    action: notify_bell
                    clear_on: focus

                  font:
                    locator: Native
                    strict_spacing: true

                    builtin_box_drawing: false
                    text_shaping:
                      engine: Native
                    render_mode: Gray

                    regular:
                      family: ${fontPreferences.monospace}
                      slant: Normal
                      weight: Regular
                      features: []

                    emoji: ${fontPreferences.emoji}

                  background:
                    blur: false
                    opacity: 1.0
                  colors: "catppuccin_mocha"
                  draw_bold_text_with_bright_colors: true

                  shell: /run/current-system/sw/bin/bash
                  arguments: []
                  initial_working_directory: "~"

                  permissions:
                    capture_buffer: ask
                    change_font: ask
                    display_host_writable_statusline: ask

              default_profile_name: main
            '';

            target = "contour/contour.yml";
            executable = null;
          };

          "contour/settings.yml" = {
            enable = true;

            source = pkgs.writeText "contour-settings.yml" ''
              {}
            '';

            target = "contour/settings.yml";
            executable = null;
          };
        };

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + T"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- org.contourterminal.Contour.desktop\")")
            ];
          }
        ];
      }
    ];

    xdg.terminal-exec = {
      enable = true;
      package = pkgs.xdg-terminal-exec;

      settings = {
        default = [
          "org.contourterminal.Contour.desktop"
        ];
      };
    };
  };
}
