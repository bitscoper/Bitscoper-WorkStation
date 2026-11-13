# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      fdroidcl
    ];

    home-manager.sharedModules = [
      {
        xdg.configFile = {
          "fdroidcl/config.toml" = {
            enable = true;

            source = pkgs.writeText "fdroidcl.toml" ''
              setups = []

              [[repos]]
              id = 'F-Droid'
              url = 'https://f-droid.org/repo'
              enabled = true

              [[repos]]
              id = 'F-Droid_Archive'
              url = 'https://f-droid.org/archive'
              enabled = true

              [[repos]]
              id = 'IzzyOnDroid'
              url = 'https://apt.izzysoft.de/fdroid/repo'
              enabled = true

              [[repos]]
              id = 'Guardian_Project'
              url = 'https://guardianproject.info/fdroid/repo'
              enabled = true

              [[repos]]
              id = 'Guardian_Project_Archive'
              url = 'https://guardianproject.info/fdroid/archive'
              enabled = true

              [[repos]]
              id = 'microG'
              url = 'https://repo.microg.org/fdroid/repo'
              enabled = true

              [[repos]]
              id = 'microG_Archive'
              url = 'https://microg.org/fdroid/archive'
              enabled = true
            '';

            target = "fdroidcl/config.toml";
            executable = null;
          };
        };
      }
    ];
  };
}
