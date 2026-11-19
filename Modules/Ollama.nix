# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cpu;

      syncModels = false;

      host = "0.0.0.0";
      port = 11434;
      openFirewall = true;
    };

    systemd.services.ollama.wantedBy = pkgs.lib.mkForce [ ]; # No Automatic Start

    environment.systemPackages = with pkgs; [
      # newelle # FIXME: Build Failure
    ];
  };
}
