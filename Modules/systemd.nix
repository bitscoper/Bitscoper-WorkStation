# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    boot = {
      kernelParams = [
        "rd.systemd.show_status=true"
      ];

      initrd.systemd = {
        package = config.systemd.package;
      };
    };

    systemd = {
      package = (
        pkgs.systemd.override {
          withAcl = true;
          withCryptsetup = true;
          withDocumentation = config.documentation.enable;
          withLogind = true;
          withOpenSSL = true;
          withPam = true;
          withPolkit = config.security.polkit.enable;
        }
      );

      settings = {
        Manager = {
          DefaultIOAccounting = true;
          DefaultIPAccounting = true;
        };
      };

      tmpfiles.rules = config.specificHardwareConfiguration.systemd.tmpfiles.rules;
    };

    networking.nameservers = [
      "9.9.9.9#dns.quad9.net"
      "149.112.112.112#dns.quad9.net"
      "2620:fe::fe#dns.quad9.net"
      "2620:fe::9#dns.quad9.net"
    ];

    services = {
      journald = {
        settings = {
          Journal = {
            Audit = "keep";

            ForwardToSyslog = false;
            Storage = "persistent";
          };
        };
      };

      logind = {
        settings = {
          Login = {
            killUserProcesses = true;

            lidSwitch = pkgs.lib.optionals config.services.upower.ignoreLid "ignore";
            lidSwitchDocked = pkgs.lib.optionals config.services.upower.ignoreLid "ignore";
            lidSwitchExternalPower = pkgs.lib.optionals config.services.upower.ignoreLid "ignore";

            powerKey = "poweroff";
            powerKeyLongPress = "poweroff";

            rebootKey = "reboot";
            rebootKeyLongPress = "reboot";

            suspendKey = "suspend";
            suspendKeyLongPress = "suspend";

            hibernateKey = "hibernate";
            hibernateKeyLongPress = "hibernate";
          };
        };
      };

      resolved = {
        enable = true;

        settings = {
          Resolve = {
            DNSSEC = true;
            DNSOverTLS = true;

            DNS = config.networking.nameservers;
            FallbackDNS = [ ];

            Domains = [
              "~."
            ];
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kjournald
    ];

    users.users.normal.extraGroups = [
      "systemd-journal"
    ];
  };
}
