# By Abdullah As-Sadeed

{
  config,
  designFactor,
  fontPreferences,
  pkgs,
  transitionDuration,
  ...
}:
{
  config = {
    programs.waybar = {
      enable = !config.home-manager.users.normal.programs.waybar.enable;
      package = (
        pkgs.waybar.override {
          cavaSupport = true;
          enableManpages = true;
          evdevSupport = true;
          experimentalPatches = true;
          gpsSupport = config.services.gpsd.enable;
          inputSupport = true;
          jackSupport = true;
          mpdSupport = false;
          mprisSupport = true;
          niriSupport = !config.programs.hyprland.enable;
          nlSupport = true;
          pipewireSupport = config.services.pipewire.enable;
          pulseSupport = config.services.pipewire.pulse.enable;
          rfkillSupport = true;
          sndioSupport = true;
          systemdSupport = true;
          traySupport = true;
          udevSupport = config.services.udev.enable;
          upowerSupport = config.services.upower.enable;
          wireplumberSupport = config.services.pipewire.wireplumber.enable;
          withMediaPlayer = true;

          runTests = false;
        }
      );
    };

    home-manager.sharedModules = [
      {
        programs.waybar = {
          enable = true;
          package = config.programs.waybar.package;

          systemd = {
            enable = true;

            enableInspect = false;
            enableDebug = config.environment.enableDebugInfo;
          };

          settings = {
            top_bar = {
              start_hidden = false;
              reload_style_on_change = true;
              position = "top";
              exclusive = true;
              layer = "top";
              passthrough = false;
              margin-top = builtins.floor (designFactor / 2.0);
              margin-right = builtins.floor (designFactor / 2.0);
              margin-bottom = 0;
              margin-left = builtins.floor (designFactor / 2.0);

              fixed-center = true;
              spacing = builtins.floor (designFactor / 2.0);

              modules-left = [
                "group/backlight-and-idle-inhibitor"
                "group/wireplumber-and-bluetooth"
                "battery"
                "group/cpu-and-load-and-temperature"
                "group/memory-and-disk"
                "network"
              ];

              modules-center = [
                "group/clock-and-user"
              ];

              modules-right = [
                "systemd-failed-units"
                "custom/swaynotificationcenter"
                "tray"
                "gamemode"
                "group/taskbar-and-workspaces"
              ];

              "group/backlight-and-idle-inhibitor" = {
                modules = [
                  "backlight"
                  "idle_inhibitor"
                ];
                drawer = {
                  click-to-reveal = false;
                  transition-left-to-right = true;
                  transition-duration = transitionDuration;
                };
                orientation = "inherit";
              };

              backlight = {
                interval = 1; # 1 Second

                format = "{percent}% {icon}";
                format-icons = [
                  ""
                  ""
                  ""
                  ""
                  ""
                  ""
                  ""
                  ""
                  ""
                ]; # Only 9 icons are available.

                tooltip = true;
                tooltip-format = "{percent}% {icon}";

                scroll-step = 1.0;
                reverse-scrolling = false;
                reverse-mouse-scrolling = false;
                on-scroll-up = "brightnessctl set +1%";
                on-scroll-down = "brightnessctl set 1%-";

                on-click = "uwsm-app -- nwg-displays.desktop & uwsm-app -- com.sidevesh.Luminance.desktop";
              };

              idle_inhibitor = {
                start-activated = false;

                format = "{icon}";
                format-icons = {
                  activated = "";
                  deactivated = "";
                };

                tooltip = true;
                tooltip-format-activated = "{status}";
                tooltip-format-deactivated = "{status}";
              };

              "group/wireplumber-and-bluetooth" = {
                modules = [
                  "wireplumber"
                  "bluetooth"
                ];
                drawer = {
                  click-to-reveal = false;
                  transition-left-to-right = true;
                  transition-duration = transitionDuration;
                };
                orientation = "inherit";
              };

              wireplumber = {
                only-physical = false;
                max-volume = 150.0; # According to Maximum Volume in pwvucontrol under Over-Amplification

                format = "{volume}% {icon} {format_source}";
                format-muted = "{icon} {format_source}";

                format-source = " {volume}% ";
                format-source-muted = "";

                format-icons = {
                  default = [
                    ""
                    ""
                    ""
                  ]; # Only 3 icons are available.
                  default-muted = "";
                };

                tooltip = true;
                tooltip-format = "Node Nickname: {node_name}\nSource Description: {source_desc}";

                scroll-step = 1.0;
                reverse-scrolling = false;
                reverse-mouse-scrolling = false;
                on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+";
                on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-";

                on-click = "uwsm-app -- pwvucontrol & uwsm-app -- org.pipewire.Helvum.desktop";
                on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
              };

              bluetooth = {
                format = "{status} {icon}";
                format-disabled = "Disabled {icon}";
                format-off = "Off {icon}";
                format-on = "On {icon}";
                format-connected = "{device_alias} {icon}";
                format-connected-battery = "{device_alias} 󰂱 ({device_battery_percentage}%)";
                format-icons = {
                  no-controller = "󰂲";
                  disabled = "󰂲";
                  off = "󰂲";
                  on = "󰂯";
                  connected = "󰂱";
                };

                tooltip = true;
                tooltip-format = "Status: {status}\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}";
                tooltip-format-disabled = "Status: Disabled";
                tooltip-format-off = "Status: Off";
                tooltip-format-on = "Status: On\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}";
                tooltip-format-connected = "Status: Connected\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}\nConnected Devices ({num_connections}): {device_enumerate}";
                tooltip-format-connected-battery = "Status: Connected\nController Address: {controller_address} ({controller_address_type})\nController Alias: {controller_alias}\nConnected Devices ({num_connections}): {device_enumerate}";
                tooltip-format-enumerate-connected = "\n\tAddress: {device_address} ({device_address_type})\n\tAlias: {device_alias}";
                tooltip-format-enumerate-connected-battery = "\n\tAddress: {device_address} ({device_address_type})\n\tAlias: {device_alias}\n\tBattery: {device_battery_percentage}%";

                on-click = "uwsm-app -- io.github.kaii_lb.Overskride.desktop";
              };

              battery = {
                design-capacity = false;
                weighted-average = true;
                interval = 1; # 1 Second

                full-at = 100;
                states = {
                  warning = 25;
                  critical = 10;
                };

                format = "{capacity}% {icon}";
                format-plugged = "{capacity}% ";
                format-charging = "{capacity}% ";
                format-full = "{capacity}% {icon}";
                format-alt = "{time} {icon}";
                format-time = "{H} h {m} min";
                format-icons = [
                  ""
                  ""
                  ""
                  ""
                  ""
                ]; # Only 5 icons are available.

                tooltip = true;
                tooltip-format = "Capacity: {capacity}%\nPower: {power} W\n{timeTo}\nCycles: {cycles}\nHealth: {health}%";

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              "group/cpu-and-load-and-temperature" = {
                modules = [
                  "cpu"
                  "load"
                  "temperature"
                ];
                drawer = {
                  click-to-reveal = false;
                  transition-left-to-right = true;
                  transition-duration = transitionDuration;
                };
                orientation = "inherit";
              };

              cpu = {
                interval = 1; # 1 Second

                format = "{usage}% ";

                tooltip = true;

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              load = {
                interval = 1; # 1 Second

                format = "{} "; # {} = {load1}

                tooltip = true;

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              temperature = {
                interval = 1; # 1 Second

                format = "{temperatureC}°C {icon}";
                format-critical = "{temperatureC}°C {icon}";
                format-icons = [
                  ""
                  ""
                  ""
                  ""
                  ""
                ]; # Only 5 icons are available.

                tooltip = true;
                tooltip-format = "{temperatureF}°F\n{temperatureK}K";

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              "group/memory-and-disk" = {
                modules = [
                  "memory"
                  "disk"
                ];
                drawer = {
                  click-to-reveal = false;
                  transition-left-to-right = true;
                  transition-duration = transitionDuration;
                };
                orientation = "inherit";
              };

              memory = {
                interval = 1; # 1 Second

                format = "{percentage}% ";

                tooltip = true;
                tooltip-format = "Used RAM: {used} GiB ({percentage}%)\nUsed Swap: {swapUsed} GiB ({swapPercentage}%)\nAvailable RAM: {avail} GiB\nAvailable Swap: {swapAvail} GiB";

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              disk = {
                path = "/";
                unit = "GB";
                interval = 1; # 1 Second

                format = "{percentage_used}% 󰋊";

                tooltip = true;
                tooltip-format = "Total: {specific_total} GB\nUsed: {specific_used} GB ({percentage_used}%)\nFree: {specific_free} GB ({percentage_free}%)";

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              network = {
                interval = 1; # 1 Second

                format = "{bandwidthUpBytes} {bandwidthDownBytes}";
                format-disconnected = "Disconnected 󱘖";
                format-linked = "No IP 󰀦";
                format-ethernet = "{bandwidthUpBytes}   {bandwidthDownBytes}";
                format-wifi = "{bandwidthUpBytes}   {bandwidthDownBytes}";

                tooltip = true;
                tooltip-format = "Interface: {ifname}\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation: {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";
                tooltip-format-disconnected = "Disconnected";
                tooltip-format-ethernet = "Interface: {ifname}\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation= {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";
                tooltip-format-wifi = "Interface: {ifname}\nESSID: {essid}\nFrequency: {frequency} GHz\nStrength: {signaldBm} dBm ({signalStrength}%)\nGateway: {gwaddr}\nSubnet Mask: {netmask}\nCIDR Notation: {cidr}\nIP Address: {ipaddr}\nUp Speed: {bandwidthUpBytes}\nDown Speed: {bandwidthDownBytes}\nTotal Speed: {bandwidthTotalBytes}";

                on-click = "uwsm-app -- org.gnome.Resources.desktop";
              };

              "group/clock-and-user" = {
                modules = [
                  "clock"
                  "user"
                ];
                drawer = {
                  click-to-reveal = false;
                  transition-left-to-right = true;
                  transition-duration = transitionDuration;
                };
                orientation = "inherit";
              };

              clock = {
                timezone = config.time.timeZone;
                locale = "en_US";
                interval = 1;

                format = "{:%I:%M %p}";
                format-alt = "{:%A, %B %d, %Y}";

                tooltip = true;
                tooltip-format = "<tt><small>{calendar}</small></tt>";

                calendar = {
                  mode = "year";
                  mode-mon-col = 3;
                  weeks-pos = "right";

                  format = {
                    months = "<b>{}</b>";
                    days = "{}";
                    weekdays = "<b>{}</b>";
                    weeks = "<i>{:%U}</i>";
                    today = "<u>{}</u>";
                  };
                };
              };

              user = {
                interval = 1; # 1 Second

                format = "{work_d}:{work_H}:{work_M}:{work_S} ";

                icon = false;

                open-on-click = false;
              };

              systemd-failed-units = {
                system = true;
                user = true;

                hide-on-ok = false;

                format = "{nr_failed_system}, {nr_failed_user} ";
                format-ok = "";

                on-click = "uwsm-app -- org.kde.kjournaldbrowser.desktop";
              };

              "custom/swaynotificationcenter" = {
                exec-if = "which swaync-client";
                exec = "swaync-client --subscribe-waybar";
                return-type = "json";
                escape = true;

                format = "{} {icon}";
                format-icons = {
                  notification = "<sup></sup>";
                  none = "";

                  inhibited-notification = "<sup></sup>";
                  inhibited-none = "";

                  dnd-notification = "<sup></sup>";
                  dnd-none = "";

                  dnd-inhibited-notification = "<sup></sup>";
                  dnd-inhibited-none = "";
                };

                tooltip = true;

                on-click = "swaync-client --toggle-panel --skip-wait";
                on-click-middle = "swaync-client --close-all --skip-wait";
                on-click-right = "swaync-client --toggle-dnd --skip-wait";
              };

              tray = {
                show-passive-items = true;
                reverse-direction = false;
                icon-size = builtins.floor (designFactor * 1.5);
                spacing = builtins.floor (designFactor / 2.0);
              };

              gamemode = {
                hide-not-running = true;

                use-icon = false;
                glyph = "󰊗";
                format = "{glyph} {count}";
                format-alt = "Games: {count}";

                tooltip = true;
                tooltip-format = "Games Running: {count}";
              };

              "group/taskbar-and-workspaces" = {
                modules = [
                  "hyprland/workspaces"
                  "wlr/taskbar"
                ];
                drawer = {
                  click-to-reveal = false;
                  transition-left-to-right = false;
                  transition-duration = transitionDuration;
                };
                orientation = "inherit";
              };

              "wlr/taskbar" = {
                all-outputs = false;
                active-first = false;
                sort-by-app-id = false;
                format = "{icon}";
                icon-size = builtins.floor (designFactor * 1.5);
                markup = true;

                tooltip = true;
                tooltip-format = "Title: {title}\nName: {name}\nID: {app_id}\nState: {state}";

                on-click = "activate";
              };

              "hyprland/workspaces" = {
                all-outputs = false;
                show-special = true;
                special-visible-only = false;
                active-only = false;
                format = "{name}";
                move-to-monitor = false;

                on-scroll-up = "hyprctl dispatch \"hl.dsp.focus({workspace = 'm-1'})\"";
                on-scroll-down = "hyprctl dispatch \"hl.dsp.focus({workspace = 'm+1'})\"";

                on-click = "hyprctl dispatch \"hl.dsp.focus({ workspace = <id> })\""; # FIXME: Does Not Work
              };
            };
          };

          style = ''
            * {
              font-family: ${fontPreferences.sansSerif};
              font-size: ${pkgs.lib.toString (builtins.floor (designFactor * 1.5))}px;
              font-weight: 500; /* Medium */
            }

            window#waybar {
              border: none;
              background-color: transparent;
            }

            .modules-right > widget:last-child > #workspaces {
              margin-right: 0px;
            }

            .modules-left > widget:first-child > #workspaces {
              margin-left: 0px;
            }

            #backlight,
            #idle_inhibitor,
            #wireplumber,
            #bluetooth,
            #battery,
            #cpu,
            #load,
            #temperature,
            #memory,
            #disk,
            #network,
            #clock,
            #user,
            #systemd-failed-units,
            #custom-swaynotificationcenter,
            #gamemode {
              border: 1px solid @surface1;
              border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
              background-color: @mantle;
              padding: ${
                pkgs.lib.toString (builtins.floor (designFactor / 4.0))
              }px ${pkgs.lib.toString (builtins.floor designFactor)}px;
              color: @lavender;
            }

            #idle_inhibitor,
            #bluetooth,
            #load,
            #temperature,
            #disk,
            #user {
              margin-left: ${pkgs.lib.toString (builtins.floor (designFactor / 2.0))}px;
            }

            #backlight,
            #cpu,
            #load,
            #temperature,
            #memory,
            #disk,
            #clock,
            #user,
            #custom-swaynotificationcenter {
              transition: background-color ${pkgs.lib.toString transitionDuration}ms;
            }

            #idle_inhibitor,
            #wireplumber,
            #bluetooth,
            #battery,
            #network,
            #systemd-failed-units,
            #gamemode {
              transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
            }

            #idle_inhibitor.deactivated {
              color: @lavender;
            }

            #idle_inhibitor.activated {
              color: @blue;
            }

            #wireplumber.muted,
            #wireplumber.sink-muted,
            #wireplumber.source-muted {
              color: @red;
            }

            #bluetooth.no-controller,
            #bluetooth.disabled,
            #bluetooth.off {
              color: @red;
            }

            #bluetooth.on,
            #bluetooth.discoverable,
            #bluetooth.pairable {
              color: @lavender;
            }

            #bluetooth.discovering,
            #bluetooth.connected {
              color: @blue;
            }

            #battery.critical {
              color: @red;
            }

            #battery.warning {
              color: @mauve;
            }

            #battery.charging {
              color: @blue;
            }

            #battery.full,
            #battery.plugged {
              color: @lavender;
            }

            #temperature.warning {
              color: @mauve;
            }

            #temperature.critical {
              color: @red;
            }

            #network.disabled,
            #network.disconnected,
            #network.linked {
              color: @red;
            }

            #network.etherenet,
            #network.wifi {
              color: @lavender;
            }

            #systemd-failed-units.degraded {
              color: @red;
            }

            #systemd-failed-units.ok {
              color: @lavender;
            }

            #gamemode.running {
              color: @blue;
            }

            #backlight:hover,
            #idle_inhibitor:hover,
            #wireplumber:hover,
            #bluetooth:hover,
            #battery:hover,
            #cpu:hover,
            #load:hover,
            #temperature:hover,
            #memory:hover,
            #disk:hover,
            #network:hover,
            #clock:hover,
            #user:hover,
            #systemd-failed-units:hover,
            #custom-swaynotificationcenter:hover,
            #gamemode:hover {
              background-color: @surface0;
            }

            #workspaces,
            #taskbar {
              background-color: transparent;
            }

            #workspaces button,
            #taskbar button {
              margin: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 4.0))}px 0px ${
                pkgs.lib.toString (builtins.floor (designFactor / 4.0))
              }px;
              border: 1px solid @surface1;
              border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
              background-color: @mantle;
              padding: 0px;
              color: @lavender;
              transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
            }

            #workspaces button {
              padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 2.0))}px 0px ${
                pkgs.lib.toString (builtins.floor (designFactor / 2.0))
              }px;
            }

            button * {
              padding: 0px ${pkgs.lib.toString (builtins.floor (designFactor / 4))}px;
            }

            #workspaces button.active,
            #taskbar button.active {
              color: @blue;
            }

            #workspaces button:hover,
            #taskbar button:hover {
              background-color: @surface0;
            }

            #tray {
              background-color: transparent;
            }

            #tray > widget {
              border: 1px solid @surface1;
              border-radius: ${pkgs.lib.toString (builtins.floor (designFactor * 2.0))}px;
              background-color: @mantle;
              color: @lavender;
              transition: background-color ${pkgs.lib.toString transitionDuration}ms, color ${pkgs.lib.toString transitionDuration}ms;
            }

            #tray > widget.passive {
              color: @lavender;
              -gtk-icon-effect: dim;
            }

            #tray > widget.active {
              color: @blue;
            }

            #tray > widget.needs-attention {
              color: @mauve;
              -gtk-icon-effect: highlight;
            }

            #tray > widget:hover {
              background-color: @surface0;
            }

            #tray image {
              padding: 0px ${pkgs.lib.toString (builtins.floor designFactor)}px 0px ${pkgs.lib.toString (builtins.floor designFactor)}px;
            }
          '';
        };

        catppuccin.waybar = {
          enable = config.home-manager.users.normal.programs.waybar.enable;

          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;

          mode = "prependImport";
        };
      }
    ];
  };
}
