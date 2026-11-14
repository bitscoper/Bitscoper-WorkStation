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
    virtualisation = {
      podman = {
        enable = true;
        package = pkgs.podman;
        extraRuntimes = with pkgs; [
          runc
        ];

        dockerCompat = true;
        dockerSocket.enable = true;

        networkSocket = {
          enable = true;

          server = "ghostunnel";

          listenAddress = "0.0.0.0";
          port = 2376;

          tls = {
            cert = tlsCertificateFile;
            key = tlsCertificatePrivateKeyFile;

            cacert = tlsCACertificateFile;
          };

          openFirewall = true;
        };

        defaultNetwork.settings = {
          dns_enabled = true;
        };
      };

      oci-containers.backend = "podman";
    };

    environment.systemPackages =
      with pkgs;
      [
        diffoci
        dive
        podman-compose
        pods
      ]
      ++ config.virtualisation.podman.extraRuntimes;

    networking.firewall.allowedTCPPorts = [
      config.virtualisation.podman.networkSocket.port
    ];

    users.users.normal.extraGroups = [
      "podman"
    ];
  };
}
