# By Abdullah As-Sadeed

{
  lib,
  ...
}:
{
  options = {
    customOptions.passwords = {
      password_1 = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Password 1";
        default = "";
        example = "";
      };

      password_2 = lib.mkOption {
        type = lib.types.str;
        internal = false;
        visible = true;
        readOnly = false;
        description = "Password 2";
        default = "";
        example = "";
      };
    };
  };

  config = {
    customOptions = {
      lutris.hardwareSpecificPaths = {
        directoryOfLutrisPrefixes = "/home/normal/Games/Lutris_Prefixes";
        directoryOfInstalledGameFiles = "/run/media/normal/Common/Installed_Game_Files/Common";
      };

      passwords = {
        password_1 = "*****************";
        password_2 = "*****************";
      };
    };

    environment.sessionVariables = {
      STEAM_COMPAT_MOUNTS = "/tmp:/run/current-system/sw/share/nix-ld/lib/";

      MESA_SHADER_CACHE_DIR = "/tmp/";
      __GL_SHADER_DISK_CACHE_PATH = "/tmp/";
    };
  };
}
