# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    nixpkgs.overlays = [
      (final: previous: {
        opendm = previous.stdenv.mkDerivation {
          pname = "opendm";
          version = "main";

          src = fetchGit {
            url = "https://github.com/nadermkhan/opendm.git";
            ref = "main";
            submodules = true;
          };

          nativeBuildInputs = with previous; [
            cmake
            pkg-config
            wrapGAppsHook4
          ];

          buildInputs = with previous; [
            curl
            gtk4
            libadwaita
            nlohmann_json
          ];
        };
      })
    ];

    environment.systemPackages = with pkgs; [
      opendm
    ];
  };
}
