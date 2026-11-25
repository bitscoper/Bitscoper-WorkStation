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
        spice-gtk = previous.spice-gtk.override {
          withPolkit = config.security.polkit.enable;
        };
      })
    ];

    boot = {
      extraModprobeConfig = ''
        options kvm ignore_msrs=1 report_ignored_msrs=0
      '';

      kernelParams = [
        "kvm.ignore_msrs=1"
      ];
    };

    virtualisation = {
      libvirtd = {
        enable = true;
        package = (
          pkgs.libvirt.override {
            enableCeph = false; # FIXME: Build Failure
            enableGlusterfs = true;
            enableIscsi = true;
            enableXen = config.virtualisation.xen.enable;
            enableZfs = true;
          }
        );

        qemu = {
          package = pkgs.qemu_full;

          vhostUserPackages = with pkgs; [
            virtiofsd
          ];

          swtpm = {
            enable = true;
            package = pkgs.swtpm;
          };

          runAsRoot = true;
        };
      };

      spiceUSBRedirection.enable = true;
    };

    services = {
      dbus.packages = with pkgs; [
        libvirt-dbus
      ];

      cockpit.plugins = with pkgs; [
        cockpit-machines
      ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/swtpm-localca 0750 tss root -"
    ];

    networking.firewall.trustedInterfaces = [
      "virbr0"
    ];

    security.wrappers = {
      spice-client-glib-usb-acl-helper = {
        source = "${pkgs.spice-gtk}/bin/spice-client-glib-usb-acl-helper";
      };
    };

    environment.systemPackages =
      with pkgs;
      [
        field-monitor
        gtk-vnc
        guestfs-tools
        libguestfs-with-appliance
        libvirt-glib
        qemu-user
        qemu-utils
        spice-glib
        spice-gtk
        virt-v2v
      ]
      ++ config.virtualisation.libvirtd.qemu.vhostUserPackages;

    programs = {
      virt-manager = {
        enable = true;
        package = (
          pkgs.virt-manager.override {
            spiceSupport = true;
          }
        );
      };

      dconf.profiles.user.databases = [
        {
          lockAll = true;

          settings = {
            "org/virt-manager/virt-manager" = {
              xmleditor-enabled = true;
            };

            "org/virt-manager/virt-manager/connections" = {
              autoconnect = [
                "qemu:///system"
              ];
              uris = [
                "qemu:///system"
              ];
            };

            "org/virt-manager/virt-manager/new-vm" = {
              cpu-default = "host-passthrough";
            };

            "org/virt-manager/virt-manager/console" = {
              auto-redirect = false;
              autoconnect = true;
            };

            "org/virt-manager/virt-manager/stats" = {
              enable-cpu-poll = true;
              enable-disk-poll = true;
              enable-memory-poll = true;
              enable-net-poll = true;
            };

            "org/virt-manager/virt-manager/vmlist-fields" = {
              cpu-usage = true;
              disk-usage = true;
              host-cpu-usage = true;
              memory-usage = true;
              network-traffic = true;
            };

            "org/virt-manager/virt-manager/confirm" = {
              delete-storage = true;
              forcepoweroff = true;
              pause = true;
              poweroff = true;
              removedev = true;
              unapplied-dev = true;
            };
          };
        }
      ];
    };

    users.users.normal.extraGroups = [
      "kvm"
      "libvirtd"
      "qemu-libvirtd"
    ];
  };
}
