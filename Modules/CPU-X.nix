# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "cpu-x" ''
        exec sudo -E ${cpu-x}/bin/cpu-x "$@"
      '')
    ];

    security.sudo.extraRules = [
      {
        users = [
          config.users.users.normal.name
        ];

        commands = [
          {
            command = "${pkgs.cpu-x}/bin/cpu-x";
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
          cpu-x =
            let
              desktopFile = "${pkgs.cpu-x}/share/applications/io.github.thetumultuousunicornofdarkness.cpu-x.desktop";

              get =
                key:
                pkgs.runCommand "${key}_from_CPU-X_Desktop_File" { } ''
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
              icon = builtins.readFile (get "Icon"); # Available in config.home-manager.users.normal.gtk.iconTheme
              comment = builtins.readFile (get "Comment");

              exec = builtins.readFile (get "Exec"); # Calls the same binary as the output of writeShellScriptBin in config.environment.systemPackages
              terminal = builtins.fromJSON (
                pkgs.lib.strings.toLower (pkgs.lib.strings.trim (builtins.readFile (get "Terminal")))
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
