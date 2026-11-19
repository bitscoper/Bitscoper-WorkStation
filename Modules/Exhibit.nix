# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      exhibit
    ];

    xdg.mime.defaultApplications = {
      "application/prs.wavefront-obj" = "io.github.nokse22.Exhibit.desktop";
      "application/vnd.ms-3mfdocument" = "io.github.nokse22.Exhibit.desktop";
      "model/*" = "io.github.nokse22.Exhibit.desktop";
    };
  };
}
