# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs = {
      gnupg = {
        package = (
          pkgs.gnupg1compat.override {
            gnupg = (
              pkgs.gnupg24.override {
                enableMinimal = false;
                guiSupport = true;
                withPcsc = true;
                withTpm2Tss = true;
              }
            );
          }
        );

        dirmngr.enable = true;

        agent = {
          enable = true;

          enableBrowserSocket = true;
          enableExtraSocket = true;

          enableSSHSupport = true;

          pinentryPackage = (
            pkgs.pinentry-qt.override {
              withLibsecret = true;
            }
          );
        };
      };
    };

    home-manager.sharedModules = [
      {
        programs.gpg = {
          enable = true;
          package = config.programs.gnupg.package;

          mutableKeys = true;
          mutableTrust = true;

          settings = {
            no-comments = false;
          };

          scdaemonSettings = {
            disable-ccid = true;
          };

          dirmngrSettings = {
            allow-version-check = true;
            keyserver = "hkps://keys.openpgp.org/";
          };

          gpgsmSettings = {
            with-key-data = true;
          };
        };

        services.gpg-agent = {
          enable = config.programs.gnupg.agent.enable;

          enableExtraSocket = config.programs.gnupg.agent.enableExtraSocket;
          enableScDaemon = true;

          enableSshSupport = config.programs.gnupg.agent.enableSSHSupport;
          enableBashIntegration = true;

          pinentry.package = config.programs.gnupg.agent.pinentryPackage;
          noAllowExternalCache = false;
          grabKeyboardAndMouse = true;
        };
      }
    ];

    environment.systemPackages =
      with pkgs;
      [
        lock
        pgpdump
      ]
      ++ [
        config.programs.gnupg.agent.pinentryPackage
      ];
  };
}
