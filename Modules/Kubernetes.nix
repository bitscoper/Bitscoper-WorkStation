# By Abdullah As-Sadeed

{
  config,
  pkgs,
  tlsCACertificateFile,
  tlsCertificateFile,
  tlsCertificatePrivateKeyFile,
  ...
}:
{
  config = {
    services = {
      etcd = {
        enable = true;
        package = pkgs.etcd;

        name = config.networking.fqdn;
        trustedCaFile = tlsCACertificateFile;
        certFile = tlsCertificateFile;
        keyFile = tlsCertificatePrivateKeyFile;

        clientCertAuth = true;
        listenClientUrls = [
          "https://0.0.0.0:2379"
        ];
        advertiseClientUrls = config.services.etcd.listenClientUrls;

        peerClientCertAuth = true;
        peerTrustedCaFile = tlsCACertificateFile;
        peerCertFile = tlsCertificateFile;
        peerKeyFile = tlsCertificatePrivateKeyFile;
        listenPeerUrls = [
          "https://0.0.0.0:2380"
        ];
        initialAdvertisePeerUrls = config.services.etcd.listenPeerUrls;

        extraConf = {
          "CORS" = "*";
        };

        openFirewall = true;
      };

      flannel = {
        enable = true;
        package = pkgs.flannel;

        nodeName = config.networking.fqdn;

        storageBackend = "kubernetes";
        kubeconfig = config.services.kubernetes.lib.mkKubeConfig "flannel" {
          server = config.services.kubernetes.apiserverAddress;

          caFile = tlsCACertificateFile;
          certFile = tlsCertificateFile;
          keyFile = tlsCertificatePrivateKeyFile;
        };

        extraNetworkConfig = {
          EnableIPv6 = true;
        };
      };

      kubernetes = {
        package = pkgs.kubernetes;

        roles = [
          "master"
          "node"
        ];

        pki.enable = false; # Done Manually Instead
        easyCerts = false; # Done Manually Instead

        masterAddress = config.networking.fqdn;
        caFile = tlsCACertificateFile;

        apiserverAddress = "https://${config.networking.fqdn}:6443";

        kubeconfig = {
          server = config.services.kubernetes.apiserverAddress;

          caFile = tlsCACertificateFile;
          certFile = tlsCertificateFile;
          keyFile = tlsCertificatePrivateKeyFile;
        };

        addonManager = {
          enable = true;
        };

        addons.dns = {
          enable = true;

          clusterDomain = config.networking.fqdn;

          reconcileMode = "Reconcile";
        };

        proxy = {
          enable = true;

          hostname = config.networking.fqdn;
          bindAddress = "0.0.0.0";

          kubeconfig = {
            server = config.services.kubernetes.apiserverAddress;

            caFile = tlsCACertificateFile;
            certFile = tlsCertificateFile;
            keyFile = tlsCertificatePrivateKeyFile;
          };
        };

        flannel = {
          enable = true;

          openFirewallPorts = true;
        };

        apiserver = {
          enable = true;

          tlsCertFile = tlsCertificateFile;
          tlsKeyFile = tlsCertificatePrivateKeyFile;
          bindAddress = "0.0.0.0";
          advertiseAddress = "0.0.0.0";
          securePort = 6443;

          storageBackend = "etcd3";
          etcd = {
            servers = [
              "https://${config.networking.fqdn}:2379"
            ];

            caFile = tlsCACertificateFile;
            certFile = tlsCertificateFile;
            keyFile = tlsCertificatePrivateKeyFile;
          };

          clientCaFile = tlsCACertificateFile;

          proxyClientCertFile = tlsCertificateFile;
          proxyClientKeyFile = tlsCertificatePrivateKeyFile;

          kubeletClientCaFile = tlsCACertificateFile;
          kubeletClientCertFile = tlsCertificateFile;
          kubeletClientKeyFile = tlsCertificatePrivateKeyFile;

          serviceAccountKeyFile = tlsCertificatePrivateKeyFile;
          serviceAccountSigningKeyFile = tlsCertificatePrivateKeyFile;

          allowPrivileged = false;
        };

        controllerManager = {
          enable = true;

          rootCaFile = tlsCACertificateFile;
          tlsCertFile = tlsCertificateFile;
          tlsKeyFile = tlsCertificatePrivateKeyFile;
          bindAddress = "0.0.0.0";
          securePort = 10252;

          serviceAccountKeyFile = tlsCertificatePrivateKeyFile;

          leaderElect = true;

          kubeconfig = {
            server = config.services.kubernetes.apiserverAddress;

            caFile = tlsCACertificateFile;
            certFile = tlsCertificateFile;
            keyFile = tlsCertificatePrivateKeyFile;
          };

          allocateNodeCIDRs = true;
        };

        scheduler = {
          enable = true;

          address = "0.0.0.0";
          port = 10251;

          leaderElect = true;

          kubeconfig = {
            server = config.services.kubernetes.apiserverAddress;

            caFile = tlsCACertificateFile;
            certFile = tlsCertificateFile;
            keyFile = tlsCertificatePrivateKeyFile;
          };
        };

        kubelet = {
          enable = true;

          hostname = config.networking.fqdn;
          tlsCertFile = tlsCertificateFile;
          tlsKeyFile = tlsCertificatePrivateKeyFile;
          address = "0.0.0.0";
          port = 10250;

          healthz = {
            bind = "0.0.0.0";
            port = 10248;
          };

          clusterDomain = config.networking.fqdn;

          kubeconfig = {
            server = config.services.kubernetes.apiserverAddress;

            caFile = tlsCACertificateFile;
            certFile = tlsCertificateFile;
            keyFile = tlsCertificatePrivateKeyFile;
          };

          clientCaFile = tlsCACertificateFile;

          containerRuntimeEndpoint = "unix:///run/containerd/containerd.sock";

          registerNode = true;
          unschedulable = false;
        };
      };
    };

    environment.systemPackages =
      with pkgs;
      [
        kubectl
        kubernetes-controller-tools
        kubescape
        kubeshark
        seabird
      ]
      ++ [
        config.services.kubernetes.package
      ];

    home-manager.sharedModules = [
      {
        programs = {
          kubecolor = {
            enable = true;
            package = pkgs.kubecolor;

            enableAlias = true;

            settings = {
              kubectl = pkgs.lib.getExe pkgs.kubectl;
              preset = "dark";
            };
          };

          mcp.servers = {
            mcp-k8s-go = {
              enabled = true;

              command = "${pkgs.mcp-k8s-go}/bin/mcp-k8s-go";
            };
          };
        };
      }
    ];
  };
}
