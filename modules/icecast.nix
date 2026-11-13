# By Abdullah As-Sadeed

{
  config,
  tlsCertificateConcatenatedFile,
  ...
}:
{
  config = {
    services.icecast = {
      enable = true;

      hostname = config.networking.fqdn;
      listen = {
        address = "0.0.0.0";
        port = 11111;
      };

      admin = {
        user = "root";
        password = config.secrets.password_1;
      };

      extraConfig = ''
        <location>${config.networking.fqdn}</location>
        <admin>root@${config.networking.fqdn}</admin>
        <authentication>
          <source-password>${config.secrets.password_2}</source-password>
          <relay-password>${config.secrets.password_2}</relay-password>
        </authentication>
        <directory>
          <yp-url>http://dir.xiph.org/cgi-bin/yp-cgi</yp-url>
        </directory>
        <paths>
        <ssl-certificate>${tlsCertificateConcatenatedFile}</ssl-certificate>
        </paths>
        <logging>
          <loglevel>2</loglevel>
        </logging>
        <server-id>${config.networking.fqdn}</server-id>
      ''; # <loglevel>2</loglevel> = Warn
    };

    networking.firewall.allowedTCPPorts = [
      config.services.icecast.listen.port
    ];
  };
}
