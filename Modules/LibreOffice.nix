# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      libreoffice # To Use the GTK Theme: Tools > "Options..." > LibreOffice > Appearance > "LibreOffice Themes" > Uncheck "Enable application theming"
    ];

    xdg.mime.defaultApplications = {
      "application/msword" = "writer.desktop";
      "application/vnd.oasis.opendocument.text" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = "writer.desktop";
      "application/vnd.openxmlformats-officedocument.wordprocessingml.template" = "writer.desktop";

      "application/vnd.ms-excel" = "calc.desktop";
      "application/vnd.oasis.opendocument.spreadsheet" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "calc.desktop";
      "application/vnd.openxmlformats-officedocument.spreadsheetml.template" = "calc.desktop";

      "application/vnd.ms-powerpoint" = "impress.desktop";
      "application/vnd.oasis.opendocument.presentation" = "impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.presentation" = "impress.desktop";
      "application/vnd.openxmlformats-officedocument.presentationml.template" = "impress.desktop";
    };
  };
}
