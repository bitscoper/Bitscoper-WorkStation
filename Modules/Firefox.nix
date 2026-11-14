# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs.firefox = {
      enable = true;
      package = pkgs.firefox-devedition;

      languagePacks = [
        "en-US"
      ];

      policies = {
        SkipTermsOfUse = true;

        DisableTelemetry = true;
        DisableFirefoxStudies = true;
        DisableFirefoxAccounts = true;
        DisablePocket = true;

        AppAutoUpdate = false;
        BackgroundAppUpdate = false;
        NoDefaultBookmarks = true;

        HardwareAcceleration = true;
        PostQuantumKeyAgreementEnabled = true;
        DisablePrivateBrowsing = false;
        CaptivePortal = true;

        DisableDeveloperTools = false;
        AllowFileSelectionDialogs = true;
        DisableBuiltinPDFViewer = false;
        VisualSearchEnabled = true;
        SearchSuggestEnabled = true;
        TranslateEnabled = true;
        PrintingEnabled = true;

        HttpsOnlyMode = "enabled";
        OfferToSaveLogins = false;
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        PromptForDownloadLocation = false;
        StartDownloadsInTempDirectory = false;

        ExtensionSettings =
          let
            linkFormat = linkPart: "https://addons.mozilla.org/firefox/downloads/latest/${linkPart}/latest.xpi";
          in
          {
            "{8446b178-c865-4f5c-8ccc-1d7887811ae3}" = {
              install_url = linkFormat "catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}-git";
              installation_mode = "normal_installed";
              updates_disabled = false;
            }; # Hardcoded Identifier for Catppuccin Mocha Lavender

            "jid1-BoFifL9Vbdl2zQ@jetpack" = {
              install_url = linkFormat "decentraleyes";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "FirefoxColor@mozilla.com" = {
              install_url = linkFormat "firefox-color";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "keepassxc-browser@keepassxc.org" = {
              install_url = linkFormat "keepassxc-browser";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "@testpilot-containers" = {
              install_url = linkFormat "multi-account-containers";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{2e5ff8c8-32fe-46d0-9fc8-6b8986621f3c}" = {
              install_url = linkFormat "search_by_image";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{531906d3-e22f-4a6c-a102-8057b88a1a63}" = {
              install_url = linkFormat "single-file";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "sponsorBlocker@ajay.app" = {
              install_url = linkFormat "sponsorblock";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "uBlock0@raymondhill.net" = {
              install_url = linkFormat "ublock-origin";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };

            "{dcb8caa2-63fa-41aa-a508-a45c5990ebdd}" = {
              install_url = linkFormat "zjm-whatfont";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };
          }
          // {
            "queryamoid@kaply.com" = {
              install_url = "https://github.com/mkaply/queryamoid/releases/download/v0.2/query_amo_addon_id-0.2-fx.xpi";
              installation_mode = "normal_installed";
              updates_disabled = false;
            };
          };
      };
    };

    home-manager.sharedModules = [
      {
        programs = {
          firefox = {
            enable = config.programs.firefox.enable;
            package = config.programs.firefox.package;

            languagePacks = config.programs.firefox.languagePacks;

            policies = config.programs.firefox.policies;
          };

          mcp.servers = {
            firefox-devtools-mcp = {
              enabled = true;

              command = "${pkgs.firefox-devtools-mcp}/bin/firefox-devtools-mcp";
              args = [
                "--firefox-path"
                "${pkgs.firefox-devedition}/bin/firefox-devedition"
                "--tool-preset"
                "developer"
              ];
            };
          };
        };

        catppuccin.firefox.enable = false; # Manually Done Instead

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + ALT + W"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- firefox-devedition.desktop\")")
            ];
          }

          {
            _args = [
              "SUPER + ALT + SHIFT + W"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"firefox-devedition --private-window\")")
            ];
          }
        ];
      }
    ];
  };
}
