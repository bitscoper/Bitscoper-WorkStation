# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    home-manager.sharedModules = [
      {
        programs.chromium = {
          enable = true;
          package = pkgs.ungoogled-chromium;

          dictionaries = with pkgs.hunspellDictsChromium; [
            en_US
          ];

          extensions =
            let
              createExtensionFromStoreFor =
                browserVersion:
                {
                  id,
                  version,
                }:
                {
                  inherit id;
                  inherit version;

                  crxPath = builtins.fetchurl {
                    url = "https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${browserVersion}&x=id%3D${id}%26installsource%3Dondemand%26uc";
                    name = "${id}.crx";
                  };
                };

              createExtensionFromStore = createExtensionFromStoreFor (
                pkgs.lib.versions.major config.home-manager.users.normal.programs.chromium.package.version
              );

              createExtensionFromAnywhere =
                {
                  id,
                  version,
                  url,
                }:
                {
                  inherit id version;

                  crxPath = builtins.fetchurl {
                    inherit url;
                    name = "${id}.crx";
                  };
                };
            in
            [
              (createExtensionFromStore {
                id = "bkkmolkhemgaeaeggcmfbghljjjoofoh";
                version = "5.0.0";
              }) # "Catppuccin Chrome Theme - Mocha"

              (createExtensionFromAnywhere {
                id = "ocaahdebbfolfmndjeplogmgcagdmblk";
                version = "1.5.5.4";
                url = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.5.4/Chromium.Web.Store.crx";
              }) # "Chromium Web Store"

              (createExtensionFromStore {
                id = "ldpochfccmkkmhdbclfhpagapcfdljkj";
                version = "3.0.2";
              }) # "Decentraleyes"

              (createExtensionFromStore {
                id = "oboonakemofpalcgghocfoadofidjkkk";
                version = "1.10.4.1";
              }) # "KeePassXC-Browser"

              (createExtensionFromStore {
                id = "cnojnbdhbhnkbcieeekonklommdnndci";
                version = "8.5.4";
              }) # "Search by Image"

              (createExtensionFromStore {
                id = "mpiodijhokgodhhofbcjdecpffjipkle";
                version = "1.36.0";
              }) # "SingleFile"

              (createExtensionFromStore {
                id = "mnjggcdmjocbbbhaepdhchncahnbgone";
                version = "6.1.6";
              }) # "SponsorBlock for YouTube - Skip Sponsorships"

              (createExtensionFromStore {
                id = "ddkjiahejlhfcafbddmgiahcphecmpfh";
                version = "2026.1103.1743";
              }) # "uBlock Origin Lite"

              (createExtensionFromStore {
                id = "jabopobgcpjmedljpbcaablpmlmfcogm";
                version = "3.3.0";
              }) # "WhatFont"
            ];
        };

        catppuccin.chromium.enable = false; # Manually Done Instead

        wayland.windowManager.hyprland.settings.bind = [
          {
            _args = [
              "SUPER + W"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"uwsm-app -- chromium-browser.desktop\")")
            ];
          }
          {
            _args = [
              "SUPER + SHIFT + W"
              (pkgs.lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"chromium-browser --incognito\")")
            ];
          }
        ];
      }
    ];

    environment.variables.CHROME_EXECUTABLE = "chromium-browser";

    xdg.mime.defaultApplications = {
      "x-scheme-handler/http" = "chromium-browser.desktop";
      "x-scheme-handler/https" = "chromium-browser.desktop";
    };
  };
}
