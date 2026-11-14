# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    nixpkgs.overlays = [
      (final: previous: {
        hardinfo2 = previous.hardinfo2.override {
          printingSupport = true;
        };
      })
    ];

    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "hardinfo2" ''
        exec sudo -E ${hardinfo2}/bin/hardinfo2 "$@"
      '')
    ];

    security.sudo.extraRules = [
      {
        users = [
          config.users.users.normal.name
        ];

        commands = [
          {
            command = "${pkgs.hardinfo2}/bin/hardinfo2";
            options = [
              "NOPASSWD"
              "SETENV"
            ];
          }
        ];
      }
    ];

    home-manager.sharedModules = [
      {
        xdg.desktopEntries = {
          hardinfo2 =
            let
              desktopFile = "${pkgs.hardinfo2}/share/applications/hardinfo2.desktop";

              get =
                key:
                pkgs.runCommand "${key}_from_Hardinfo2_Desktop_File" { } ''
                  ${pkgs.python3}/bin/python3 - << 'EOF' > $out
                  import configparser

                  parser = configparser.ConfigParser(strict=False)

                  parser.read("${desktopFile}")
                  value = parser.get("Desktop Entry", "${key}", fallback="")
                  print(value)
                  EOF
                '';
            in
            {
              type = pkgs.lib.strings.trim (builtins.readFile (get "Type"));
              categories = pkgs.lib.splitString ";" (builtins.readFile (get "Categories"));

              name = builtins.readFile (get "Name");
              icon = "${pkgs.hardinfo2}/share/icons/hicolor/scalable/apps/hardinfo2.svg";
              comment = builtins.readFile (get "Comment");

              exec = builtins.readFile (get "Exec"); # Calls the same binary as the output of writeShellScriptBin in config.environment.systemPackages
              terminal = builtins.fromJSON (
                pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "Terminal")))
              );
              startupNotify = builtins.fromJSON (
                pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "StartupNotify")))
              );

              settings = {
                Keywords = builtins.readFile (get "Keywords");
              };
            };
        };
      }
    ];
  };
}
