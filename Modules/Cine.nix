# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      cine
    ];

    xdg.mime.defaultApplications = {
      "video/*" = "io.github.diegopvlk.Cine.desktop";
    };
  };
}
