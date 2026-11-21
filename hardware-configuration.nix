# By Abdullah As-Sadeed

{
  lib,
  ...
}:
{
  options = {
    secrets = {
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
    secrets = {
      password_1 = "*****************";
      password_2 = "*****************";
    };
  };
}
