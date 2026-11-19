# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    programs.appimage = {
      enable = true;
      package = (
        pkgs.appimage-run.override {
          extraPkgs =
            pkgs: with pkgs; [
              libepoxy
              libsoup_3
              webkitgtk_4_1
            ];
        }
      );

      binfmt = true;
    };

    environment.systemPackages = with pkgs; [
      # gearlever # FIXME: Build Failure
      appimageupdate-qt
    ];
  };
}
