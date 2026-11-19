# By Abdullah As-Sadeed

{
  config,
  pkgs,
  ...
}:
let
  androidSDKCompositionFlake = builtins.getFlake "github:tadfisher/android-nixpkgs/stable";
  androidSDKCompositionFromTadFisher =
    androidSDKCompositionFlake.sdk.${config.nixpkgs.hostPlatform.system}
      (
        sdkPkgs: with sdkPkgs; [
          build-tools-35-0-0
          build-tools-36-0-0
          build-tools-36-1-0
          build-tools-37-0-0

          (cmake-3-22-1.overrideAttrs (oldAttributes: {
            passthru = (oldAttributes.passthru or { }) // {
              installSdk = ((oldAttributes.passthru or { }).installSdk or "") + ''
                chmod u+w "$pkgBase/bin/"

                rm -f "$pkgBase/bin/ninja"
                ln -s ${pkgs.ninja}/bin/ninja "$pkgBase/bin/ninja"
              '';
            };
          })) # Fixes Error
          cmake-4-1-2

          cmdline-tools-latest

          emulator

          ndk-28-2-13676358
          ndk-29-0-14206865
          ndk-30-0-16248370

          platform-tools

          platforms-android-28
          platforms-android-29
          platforms-android-30
          platforms-android-31
          platforms-android-32
          platforms-android-33
          platforms-android-34
          platforms-android-35
          platforms-android-36
          platforms-android-36-1
          platforms-android-37-0
          platforms-android-37-1
          platforms-android-37-2

          system-images-android-37-0-default-x86-64
        ] # https://github.com/tadfisher/android-nixpkgs/tree/main/channels/
      );
in
{
  config = {
    nixpkgs.config.androidSDKCompositionFromTadFisher.accept_license =
      config.nixpkgs.config.allowUnfree;

    programs.java = {
      enable = true;
      package = (
        pkgs.jdk25.override {
          enableGtk = true;
        }
      );

      binfmt = true;
    };

    environment = {
      systemPackages =
        with pkgs;
        [
          android-tools
          clang-analyzer
          clang-tools
          clang_22
          cmake-format
          cmake-lint
          flutter
          lld_22
          llvm_22
          ninja
          pkg-config
          rubyPackages.cocoapods
          scrcpy
          swift
          swift-format
          swiftpm
          zenity

          (cmake.override {
            buildDocs = true;
            isMinimalBuild = false;
            useOpenSSL = true;
          })
        ]
        ++ pkgs.lib.optionals config.nixpkgs.config.allowUnfree [
          androidSDKCompositionFromTadFisher
        ];

      variables = {
        JAVA_HOME = "${config.programs.java.package}/lib/openjdk";
        CHROME_EXECUTABLE = "chromium-browser";
      }
      // pkgs.lib.optionalAttrs config.nixpkgs.config.allowUnfree {
        ANDROID_HOME = "${androidSDKCompositionFromTadFisher}/share/android-sdk/";
        ANDROID_SDK_ROOT = "${androidSDKCompositionFromTadFisher}/share/android-sdk/";
      };
    };
  };
}
