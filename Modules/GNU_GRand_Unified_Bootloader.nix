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
        catppuccin-grub =
          (previous.catppuccin-grub.override {
            flavor = config.catppuccin.flavor;
          }).overrideAttrs
            (oldAttributes: {
              postInstall = (oldAttributes.postInstall or "") + ''
                cp ${themedBgrtPngFile} $out/background.png

                rm -f $out/logo.png
                sed -i '/# Logo image/,+5d' $out/theme.txt
              '';
            });
      })
    ];

    boot.loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;

        copyKernels = true;

        efiSupport = true;
        zfsSupport = true;
        enableCryptodisk = true;
        useOSProber = true;

        fsIdentifier = "uuid";
        device = "nodev";

        gfxmodeEfi = "${pkgs.lib.toString (config.specificHardwareConfiguration.screen.width)}x${pkgs.lib.toString (config.specificHardwareConfiguration.screen.height)},auto";
        gfxpayloadEfi = "keep";
        splashMode = "normal";

        theme = "${pkgs.catppuccin-grub}/";
        splashImage = pkgs.lib.mkForce "${themedBgrtPngFile}";

        configurationLimit = 100;
        extraEntriesBeforeNixOS = false;

        memtest86 = {
          enable = true;

          params = [
            "btrace"
          ];
        };

        forceInstall = false;
      };

      timeout = 1; # 1 Second
    };

    catppuccin.grub.enable = false; # Done Manually Instead
  };
}
