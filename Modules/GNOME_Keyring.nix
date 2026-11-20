# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
{
  config = {
    programs = {
      nix-ld.libraries = with pkgs; [
        libsecret
      ];

      seahorse.enable = true;
    };

    services.gnome.gnome-keyring.enable = true;

    home-manager.sharedModules = [
      {
        services.gnome-keyring = {
          enable = config.services.gnome.gnome-keyring.enable;
          package = pkgs.gnome-keyring;

          components = [
            "pkcs11"
            "secrets"
          ];
        };
      }
    ];

    xdg.portal.extraPortals = [
      config.home-manager.users.normal.services.gnome-keyring.package
    ];

    environment.systemPackages = with pkgs; [
      libsecret
    ];
  };
}
