# By Abdullah As-Sadeed

{
  config,
  pkgs,
  tlsCACertificateFile,
  tlsCertificateFile,
  tlsCertificatePrivateKeyFile,
  ...
}:
let
  schedulerTlsCertificateFiles =
    pkgs.runCommand "Kubernetes_Scheduler_TLS_Certificate_Files"
      {
        nativeBuildInputs = with pkgs; [
          openssl
        ];
      }
      ''
        set -euo pipefail

        mkdir -p "$out"

        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out "$out/Private.key"

        openssl req -new -key "$out/Private.key" -out Scheduler.csr -subj "/CN=system:kube-scheduler"

        cat > Scheduler_Extensions.cnf <<EOF
        [scheduler_tls_certificate]
        basicConstraints = critical, CA:FALSE
        keyUsage = critical, digitalSignature
        extendedKeyUsage = clientAuth
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer
        EOF

        serial="$(openssl rand -hex 16)"

        openssl x509 -req -in Scheduler.csr -CA "${tlsCACertificateFile}" -CAkey "${tlsCertificatePrivateKeyFile}" -set_serial "0x$serial" -out "$out/Certificate.crt" -days 365 -sha512 -extfile Scheduler_Extensions.cnf -extensions scheduler_tls_certificate
      '';

  administratorTlsCertificateFiles =
    pkgs.runCommand "Kubernetes_Administrator_TLS_Certificate_Files"
      {
        nativeBuildInputs = with pkgs; [
          openssl
        ];
      }
      ''
        set -euo pipefail

        mkdir -p "$out"

        openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:prime256v1 -out "$out/Private.key"

        openssl req -new -key "$out/Private.key" -out Administrator.csr -subj "/O=system:masters/CN=cluster-admin"

        cat > Administrator_Extensions.cnf <<EOF
        [administrator_tls_certificate]
        basicConstraints = critical, CA:FALSE
        keyUsage = critical, digitalSignature
        extendedKeyUsage = clientAuth
        subjectKeyIdentifier = hash
        authorityKeyIdentifier = keyid,issuer
        EOF

        printf '1000\n' > CA.srl

        openssl x509 -req -in Administrator.csr -CA "${tlsCACertificateFile}" -CAkey "${tlsCertificatePrivateKeyFile}" -CAserial CA.srl -out "$out/Certificate.crt" -days 365 -sha512 -extfile Administrator_Extensions.cnf -extensions administrator_tls_certificate
      '';

  administratorKubeconfig = config.services.kubernetes.lib.mkKubeConfig "cluster-admin" {
    server = config.services.kubernetes.apiserverAddress;

    caFile = tlsCACertificateFile;
    certFile = "${administratorTlsCertificateFiles}/Certificate.crt";
    keyFile = "${administratorTlsCertificateFiles}/Private.key";
  };

  bootstrapAddonFiles = pkgs.lib.mapAttrsToList (
    name: resource: pkgs.writeText "kubernetes-bootstrap-${name}.json" (builtins.toJSON resource)
  ) config.services.kubernetes.addonManager.bootstrapAddons;
in
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
        advertiseClientUrls = [
          "https://${config.networking.fqdn}:2379"
        ];

        peerClientCertAuth = true;
        peerTrustedCaFile = tlsCACertificateFile;
        peerCertFile = tlsCertificateFile;
        peerKeyFile = tlsCertificatePrivateKeyFile;
        listenPeerUrls = [
          "https://0.0.0.0:2380"
        ];
        initialAdvertisePeerUrls = [
          "https://${config.networking.fqdn}:2380"
        ];

        initialCluster = [
          "${config.networking.fqdn}=https://${config.networking.fqdn}:2380"
        ];

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

          bootstrapAddons = {
            clusterAdministrator = {
              apiVersion = "rbac.authorization.k8s.io/v1";
              kind = "ClusterRoleBinding";

              metadata.name = "clusterAdministrator";

              roleRef = {
                apiGroup = "rbac.authorization.k8s.io";
                kind = "ClusterRole";
                name = "cluster-admin";
              };

              subjects = [
                {
                  kind = "User";
                  name = config.networking.fqdn;
                  apiGroup = "rbac.authorization.k8s.io";
                }
              ];
            };
          };
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

          apiAudiences = "api,https://kubernetes.default.svc.${config.networking.fqdn}";

          clientCaFile = tlsCACertificateFile;

          proxyClientCertFile = tlsCertificateFile;
          proxyClientKeyFile = tlsCertificatePrivateKeyFile;

          kubeletClientCaFile = tlsCACertificateFile;
          kubeletClientCertFile = tlsCertificateFile;
          kubeletClientKeyFile = tlsCertificatePrivateKeyFile;

          serviceAccountIssuer = "https://kubernetes.default.svc.${config.networking.fqdn}";
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
            certFile = "${schedulerTlsCertificateFiles}/Certificate.crt";
            keyFile = "${schedulerTlsCertificateFiles}/Private.key";
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

          extraOpts = "--fail-swap-on=false";
        };
      };
    };

    systemd = {
      services = {
        kube-addon-manager = {
          environment.KUBECONFIG = config.services.kubernetes.lib.mkKubeConfig "addon-manager" {
            server = config.services.kubernetes.apiserverAddress;

            caFile = tlsCACertificateFile;
            certFile = tlsCertificateFile;
            keyFile = tlsCertificatePrivateKeyFile;
          };

          preStart = ''
            export KUBECONFIG=${administratorKubeconfig}

            ${pkgs.lib.concatMapStringsSep "\n" (file: ''
              ${config.services.kubernetes.package}/bin/kubectl apply -f ${file}
            '') bootstrapAddonFiles}
          '';

          serviceConfig.PermissionsStartOnly = true;
          wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
        };

        etcd.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
        flannel.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start

        kube-proxy.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
        kube-apiserver.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
        kube-controller-manager.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
        kube-scheduler.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
        kubelet.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
      };

      targets.kubernetes.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start
    };

    environment = {
      systemPackages =
        with pkgs;
        [
          # kubectl-validate # FIXME: Build Failure
          kubectl
          kubectl-doctor
          kubectl-evict-pod
          kubectl-graph
          kubectl-images
          kubectl-ktop
          kubectl-neat
          kubectl-node-shell
          kubectl-tree
          kubectl-view-secret
          kubescape
          kubeshark
          seabird
        ]
        ++ [
          config.services.kubernetes.package
        ];

      shellAliases = {
        start_kubernetes = "sudo systemctl start etcd.service flannel.service kube-proxy.service kube-addon-manager.service kube-apiserver.service kube-controller-manager.service kube-scheduler.service kubelet.service";

        stop_kubernetes = "sudo systemctl stop etcd.service flannel.service kube-proxy.service kube-addon-manager.service kube-apiserver.service kube-controller-manager.service kube-scheduler.service kubelet.service";
      };
    };

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

        home = {
          file.".kube/config" = {
            enable = true;

            source = administratorKubeconfig;

            target = ".kube/config";
            executable = false;
          };

          sessionVariables = {
            KUBECONFIG = "$HOME/.kube/config";
          };
        };
      }
    ];
  };
}
