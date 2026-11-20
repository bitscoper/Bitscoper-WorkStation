# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      curtail
    ];

    programs.dconf.profiles.user.databases = [
      {
        lockAll = true;

        settings = {
          "com/github/huluti/Curtail" = {
            new-file = true;
            png-lossless-level = pkgs.lib.gvariant.mkInt32 6;
            recursive = true;
            webp-lossless-level = pkgs.lib.gvariant.mkInt32 6;
          }; # https://raw.githubusercontent.com/Huluti/Curtail/main/data/com.github.huluti.Curtail.gschema.xml
        };
      }
    ];
  };
}
