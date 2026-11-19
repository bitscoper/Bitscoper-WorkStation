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
        programs.zed-editor = {
          enable = true;
          package = (
            pkgs.zed-editor.override {
              buildRemoteServer = config.home-manager.users.normal.programs.zed-editor.installRemoteServer;
            }
          );
          installRemoteServer = true;

          extraPackages =
            with pkgs;
            [
              arduino-language-server
              basedpyright
              bash-language-server
              css-variables-language-server
              ctags-lsp
              docker-compose-language-service
              dockerfile-language-server
              kotlin-language-server
              nixd
              nixfmt
              postgres-language-server
              prettier
              ruff
              shellcheck
              shfmt
              sql-formatter
              yaml-language-server
            ]
            ++ [
              config.programs.evince.package
            ];

          enableMcpIntegration = true;

          # curl -s https://raw.githubusercontent.com/zed-industries/extensions/main/.gitmodules
          extensions = [
            "arduino"
            "assembly"
            "awk"
            "basher"
            "bloc"
            "bookmark"
            "catppuccin"
            "catppuccin-icons"
            "comment"
            "comment-block-snippets"
            "css-variables"
            "csv"
            "ctags"
            "dart"
            "desktop"
            "docker-compose"
            "dockerfile"
            "editorconfig"
            "emoji-completions"
            "env"
            "flutter-snippets"
            "git-firefly"
            "github-actions"
            "github-activity-summarizer"
            "gitignore-templates"
            "graphql"
            "graphviz"
            "groovy"
            "html-snippets"
            "http"
            "import-cost-lsp"
            "ini"
            "intl-lens"
            "javascript-snippets"
            "keep-a-changelog-snippets"
            "kubernetes-snippets"
            "latex"
            "live-server"
            "log"
            "logcat"
            "ltex"
            "lua"
            "make"
            "markdown-snippets"
            "markdownlint"
            "mermaid"
            "nix"
            "pbxproj"
            "php"
            "php-snippets"
            "phpcs"
            "phpmd"
            "platformio"
            "postgres-context-server"
            "postgres-language-server"
            "powershell"
            "python-requirements"
            "python-snippets"
            "regedit"
            "riverpod-dart-flutter-snippets"
            "rpmspec"
            "sieve"
            "sql"
            "ssh-config"
            "stylelint"
            "toml"
            "unicode"
            "vcard"
            "xml"
          ];

          mutableUserDebug = true;
          mutableUserKeymaps = true;
          mutableUserSettings = true;
          mutableUserTasks = true;

          userSettings = {
            telemetry = {
              diagnostics = false;
              metrics = false;
            };

            title_bar = {
              show_branch_name = true;
              show_branch_status_icon = true;
              show_menus = true;
              show_onboarding_banner = true;
              show_project_items = true;
              show_sign_in = true;
              show_user_menu = true;
              show_user_picture = true;
            };

            toolbar = {
              agent_review = true;
              breadcrumbs = true;
              code_actions = true;
              quick_actions = true;
              selections_menu = true;
            };

            status_bar = {
              active_language_button = true;
              cursor_position_button = true;
              line_endings_button = true;
            };
            line_indicator_format = "long";

            project_panel = {
              dock = "left";
              button = true;

              scrollbar = {
                show = "auto";
              };

              sticky_scroll = true;
              entry_spacing = "comfortable";

              indent_guides = {
                show = "always";
              };

              hide_root = false;
              hide_hidden = false;
              sort_mode = "directories_first";

              file_icons = true;
              git_status = true;
              show_diagnostics = "all";

              drag_and_drop = true;
            };

            file_finder = {
              file_icons = true;
            };

            outline_panel = {
              dock = "left";
              button = true;

              file_icons = true;
              git_status = true;

              indent_guides = {
                show = "always";
              };

              scrollbar = {
                show = "auto";
              };
            };

            git_panel = {
              dock = "left";
              button = true;

              scrollbar = {
                show = "auto";
              };
            };

            collaboration_panel = {
              dock = "right";
              button = true;
            };

            bottom_dock_layout = "full";
            terminal = {
              dock = "bottom";
              flexible = true;
              button = true;

              toolbar = {
                breadcrumbs = true;
              };

              scrollbar = {
                show = "auto";
              };

              font_family = fontPreferences.monospace;
              font_size = builtins.floor (designFactor * 2.0);
              line_height = "comfortable";

              cursor_shape = "bar";
              blinking = "on";

              copy_on_select = false;
              keep_selection_on_copy = true;

              detect_venv = {
                on = {
                  directories = [
                    ".venv"
                    "venv"
                  ];

                  activate_script = "default";
                };
              };

              env = {
                EDITOR = "zeditor --wait";
                VISUAL = "zeditor --wait";
                GIT_EDITOR = "zeditor --wait";
              };
            };

            debugger = {
              dock = "left";
              button = true;
            };

            tab_bar = {
              show = true;

              show_tab_bar_buttons = true;
              show_nav_history_buttons = true;
            };

            tabs = {
              file_icons = true;

              show_close_button = "hover";
              close_position = "right";

              git_status = true;
              show_diagnostics = "all";
            };

            search = {
              button = true;
            };

            gutter = {
              line_numbers = true;
              runnables = true;
              breakpoints = true;
              folds = true;
            };

            scrollbar = {
              show = "auto";
              axes = {
                horizontal = true;
                vertical = true;
              };

              cursors = true;
              diagnostics = "all";
              git_diff = true;
              search_results = true;
              selected_symbol = true;
              selected_text = true;
            };

            minimap = {
              show = "auto";
              display_in = "all_editors";
              thumb = "always";
            };

            sticky_scroll = {
              enabled = true;
            };

            indent_guides = {
              enabled = true;

              coloring = "indent_aware";
              background_coloring = "disabled";
            };

            git = {
              inline_blame = {
                enabled = true;

                show_commit_summary = true;
              };

              hunk_style = "staged_hollow";
            };

            diagnostics = {
              button = true;

              inline = {
                enabled = true;
              };
            };

            inlay_hints = {
              enabled = true;

              show_background = false;

              show_type_hints = true;
              show_parameter_hints = true;
              show_other_hints = true;
            };

            drag_and_drop_selection = {
              enabled = true;
            };

            edit_predictions = {
              mode = "subtle";

              provider = "ollama";
              ollama = { };
            };

            agent = {
              enabled = true;

              dock = "right";
              flexible = true;
              button = true;

              # default_model = {
              #   provider = "ollama";
              # };

              # inline_alternatives = [
              #   {
              #     provider = "ollama";
              #   }
              # ];
            };

            journal = {
              hour_format = "hour12";
            };

            image_viewer = {
              unit = "binary";
            };

            session = {
              restore_unsaved_buffers = true;
            };

            use_system_prompts = true;
            use_system_path_prompts = true;
            close_on_file_delete = false;
            confirm_quit = true;

            vim_mode = false;
            helix_mode = false;
            hide_mouse = "never";

            show_call_status_icon = true;

            ui_font_family = fontPreferences.sansSerif;
            ui_font_size = builtins.floor (designFactor * 2.0);

            agent_ui_font_family = fontPreferences.sansSerif;
            agent_ui_font_size = builtins.floor (designFactor * 2.0);

            buffer_font_family = fontPreferences.monospace;
            buffer_font_size = builtins.floor (designFactor * 2.0);
            buffer_line_height = "comfortable";

            agent_buffer_font_family = fontPreferences.monospace;
            agent_buffer_font_size = builtins.floor (designFactor * 2.0);

            mouse_wheel_zoom = true;

            cursor_shape = "bar";
            cursor_blink = true;

            soft_wrap = "editor_width";
            show_whitespaces = "all";
            show_wrap_guides = true;
            lsp_document_colors = "inlay";
            colorize_brackets = true;
            current_line_highlight = "all";
            selection_highlight = true;
            rounded_selection = true;

            inline_code_actions = true;
            hover_popover_enabled = true;
            hover_popover_sticky = true;
            code_lens = "on";

            disable_ai = false;
            show_completions_on_input = true;
            show_completion_documentation = true;
            completion_menu_scrollbar = "auto";
            auto_signature_help = true;
            show_signature_help_after_edits = true;

            use_auto_surround = true;
            extend_comment_on_newline = false;
            auto_indent = "syntax_aware";
            auto_indent_on_paste = true;
            hard_tabs = false;
            tab_size = 2;

            line_ending = "detect";
            format_on_save = "on";
            redact_private_values = true;

            file_types = {
              Diff = [
                "diff"
              ];

              "Git Attributes" = [
                "**/{git,.git,.git/info}/attributes"
              ];
              "Git Config" = [
                "*.gitconfig"
                "**/{git,.git,.git/modules,.git/modules/*}/config"
              ];
              "Git Ignore" = [
                "**/{git,.git}/ignore"
                "**/.git/info/exclude"
              ];

              "HTML" = [
                "*.svg"
                "*.xhtml"
              ];

              Dockerfile = [
                "Dockerfile.*"
              ];

              "GitHub Actions" = [
                ".github/workflows/*.yaml"
                ".github/workflows/*.yml"
              ];

              "Python constraints" = [
                "*constraints*.txt"
              ];
              "Python requirements" = [
                "**/requirements/*.{in,txt}"
                "*requirements*.{in,txt}"
              ];

              "JSON" = [
                "*.webmanifest"
              ];
            };

            languages = {
              Nix = {
                language_servers = [
                  "nixd"
                  "!nil"
                ];

                formatter = {
                  external = {
                    command = "nixfmt";
                    arguments = [ ];
                  };
                };
              };

              "Shell Script" = {
                formatter = {
                  external = {
                    command = "shfmt";
                    arguments = [
                      "--filename"
                      "{buffer_path}"
                      "--indent"
                      "2"
                    ];
                  };
                };
              };

              C = {
                language_servers = [
                  "ctags-lsp"
                ];
              };

              "C++" = {
                language_servers = [
                  "ctags-lsp"
                ];
              };

              PHP = {
                language_servers = [
                  "phpactor"
                  "phpcs"
                  "phpmd"
                  "ctags-lsp"
                  "!intelephense"
                  "!phptools"
                ];

                code_actions_on_format = {
                  "source.fixAll" = true;
                };
              };

              JavaScript = {
                formatter = {
                  external = {
                    command = "prettier";
                    arguments = [
                      "--stdin-filepath"
                      "{buffer_path}"
                    ];
                  };
                };

                code_actions_on_format = {
                  "source.fixAll.eslint" = true;
                };
              };

              Python = {
                language_servers = [
                  "basedpyright"
                  "ruff"
                  "ctags-lsp"
                ];

                formatter = {
                  language_server = {
                    name = "ruff";
                  };
                };

                code_actions_on_format = {
                  "source.organizeImports.ruff" = true;
                };
              };

              SQL = {
                formatter = {
                  external = {
                    command = "sql-formatter";
                    # arguments = [
                    #   "--language"
                    #   "postgresql"
                    # ];

                    # # Or

                    # arguments = [
                    #   "--language"
                    #   "mariadb"
                    # ];
                  };
                };
              };

              CSS = {
                code_actions_on_format = {
                  "source.fixAll.stylelint" = true;
                };
              };

              Markdown = {
                indent_list_on_tab = true;
                extend_list_on_newline = true;

                remove_trailing_whitespace_on_save = false;
              };
            };

            global_lsp_settings = {
              button = true;

              semantic_token_rules = [
                {
                  token_type = "comment";
                }
              ];
            };

            lsp = {
              # unicode = {
              #   settings = {
              #     include_all_symbols = true;
              #   };
              # }; # FIXME: Errors

              nixd = {
                initialization_options = {
                  formatting = {
                    command = [
                      "nixfmt"
                    ];
                  };
                };
              };

              clangd = {
                binary = {
                  path = "${pkgs.clang-tools}/bin/clangd";
                  arguments = [ ];
                };
              };

              arduino-language-server = {
                binary = {
                  path = "${pkgs.arduino-language-server}/bin/arduino-language-server";
                  arguments = [
                    "--fqbn"
                    "arduino:avr"
                  ];
                };
              };

              dart = {
                binary = {
                  path = "${pkgs.flutter}/bin/dart";
                  arguments = [
                    "language-server"
                    "--protocol=lsp"
                  ];
                };
              };

              phpmd = {
                settings = {
                  rulesets = "cleancode,codesize,controversial,design,naming,unusedcode";
                };
              };

              eslint = {
                settings = {
                  workingDirectory = {
                    mode = "auto";
                  };
                };
              };

              css-variables = {
                settings = {
                  cssVariables = {
                    undefinedVarFallback = "info";
                  };
                };
              };

              ltex = {
                settings = {
                  ltex = {
                    language = "auto";
                  };
                };
              };
              texlab = {
                settings = {
                  texlab = {
                    build = {
                      onSave = true;
                      forwardSearchAfter = true;
                    };

                    forwardSearch = {
                      executable = "evince-synctex";
                      args = [
                        "-f"
                        "%l"
                        "%p"
                        "\"texlab -i %f -l %l\""
                      ];
                    };
                  };
                };
              };

              yaml-language-server = {
                binary = {
                  path = "${pkgs.yaml-language-server}/bin/yaml-language-server";
                  arguments = [ ];
                };

                settings = {
                  yaml = {
                    schemaStore = {
                      enable = true;
                    };

                    keyOrdering = true;
                    singleQuote = false;
                  };
                };
              };
            };
          };

          # userTasks = {
          # };

          # userDebug = {
          # };

          # userKeymaps = {
          # };

          defaultEditor = false; # Done Manually Instead
        };

        catppuccin.zed = {
          enable = config.home-manager.users.normal.programs.zed-editor.enable;

          flavor = config.catppuccin.flavor;
          accent = config.catppuccin.accent;

          icons = {
            enable = true;

            flavor = config.catppuccin.flavor;
          };

          italics = false;
        };

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + E"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- dev.zed.Zed.desktop\")")
            ];
          }
        ];
      }
    ];

    environment = {
      systemPackages = config.home-manager.users.normal.programs.zed-editor.extraPackages;

      sessionVariables = {
        EDITOR = "zeditor --wait";
        VISUAL = "zeditor --wait";
        GIT_EDITOR = "zeditor --wait";
      };
    };

    xdg.mime.defaultApplications = {
      "application/gml+xml" = "dev.zed.Zed.desktop";
      "application/rdf+xml" = "dev.zed.Zed.desktop";
      "application/rss+xml" = "dev.zed.Zed.desktop";
      "application/x-zerosize" = "dev.zed.Zed.desktop";
      "application/xhtml+xml" = "dev.zed.Zed.desktop";
      "application/xhtml_xml" = "dev.zed.Zed.desktop";
      "application/xml" = "dev.zed.Zed.desktop";

      "text/*" = "dev.zed.Zed.desktop";
    };
  };
}
