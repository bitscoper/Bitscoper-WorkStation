# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    programs.uwsm = {
      enable = true;
      package = (
        pkgs.uwsm.override {
          fumonSupport = true;
          uuctlSupport = false;
          uwsmAppSupport = true;
        }
      );
    };
  };
}
