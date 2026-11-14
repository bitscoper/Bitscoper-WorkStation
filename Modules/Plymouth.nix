# By Abdullah As-Sadeed

{
  config,
  pkgs,
  themedBgrtPngFile,
  ...
}:
{
  config = {
    nixpkgs.overlays = [
      (final: previous: {
        catppuccin-plymouth =
          (previous.catppuccin-plymouth.override {
            variant = config.catppuccin.flavor;
          }).overrideAttrs
            (oldAttributes: {
              postInstall = (oldAttributes.postInstall or "") + ''
                THEME_DIRECTORY=$out/share/plymouth/themes/catppuccin-${config.catppuccin.flavor}
                mkdir -p $THEME_DIRECTORY

                cp ${themedBgrtPngFile} $THEME_DIRECTORY/background.png

                sed -i 's/VerticalAlignment=.*/VerticalAlignment=.90/g' $THEME_DIRECTORY/catppuccin-${config.catppuccin.flavor}.plymouth
                sed -i 's/DialogVerticalAlignment=.*/DialogVerticalAlignment=.90/g' $THEME_DIRECTORY/catppuccin-${config.catppuccin.flavor}.plymouth
              '';
            });
      })
    ];

    boot.plymouth = {
      enable = true;

      themePackages = with pkgs; [
        catppuccin-plymouth
      ];
      theme = "catppuccin-${config.catppuccin.flavor}";

      font = "${config.home-manager.users.normal.gtk.font.package}/share/fonts/truetype/NerdFonts/Noto/NotoSansNerdFont-Regular.ttf";

      logo = builtins.fetchurl {
        url = "https://upload.wikimedia.org/wikipedia/commons/c/ca/1x1.png";
      }; # Due to zero margin between the logo and throbber, and because the shutdown screen does not render the logo like the boot screen.

      showDelay = 0;

      extraConfig = ''
        UseFirmwareBackground=false
      ''; # Done Manually Instead
    };

    catppuccin.plymouth.enable = false; # Done Manually Instead
  };
}
