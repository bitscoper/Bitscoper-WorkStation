# By Abdullah As-Sadeed

{
  pkgs,
  ...
}:
{
  config = {
    environment.systemPackages = with pkgs; [
      loupe
    ];

    xdg.mime.defaultApplications = {
      "image/aces" = "org.gnome.Loupe.desktop";
      "image/apng" = "org.gnome.Loupe.desktop";
      "image/avci" = "org.gnome.Loupe.desktop";
      "image/avcs" = "org.gnome.Loupe.desktop";
      "image/avif" = "org.gnome.Loupe.desktop";
      "image/bmp" = "org.gnome.Loupe.desktop";
      "image/cgm" = "org.gnome.Loupe.desktop";
      "image/dicom-rle" = "org.gnome.Loupe.desktop";
      "image/dpx" = "org.gnome.Loupe.desktop";
      "image/emf" = "org.gnome.Loupe.desktop";
      "image/fits" = "org.gnome.Loupe.desktop";
      "image/g3fax" = "org.gnome.Loupe.desktop";
      "image/gif" = "org.gnome.Loupe.desktop";
      "image/heic" = "org.gnome.Loupe.desktop";
      "image/heic-sequence" = "org.gnome.Loupe.desktop";
      "image/heif" = "org.gnome.Loupe.desktop";
      "image/heif-sequence" = "org.gnome.Loupe.desktop";
      "image/hej2k" = "org.gnome.Loupe.desktop";
      "image/hsj2" = "org.gnome.Loupe.desktop";
      "image/ief" = "org.gnome.Loupe.desktop";
      "image/j2c" = "org.gnome.Loupe.desktop";
      "image/jaii" = "org.gnome.Loupe.desktop";
      "image/jais" = "org.gnome.Loupe.desktop";
      "image/jls" = "org.gnome.Loupe.desktop";
      "image/jp2" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "image/jph" = "org.gnome.Loupe.desktop";
      "image/jphc" = "org.gnome.Loupe.desktop";
      "image/jpm" = "org.gnome.Loupe.desktop";
      "image/jpx" = "org.gnome.Loupe.desktop";
      "image/jxl" = "org.gnome.Loupe.desktop";
      "image/jxr" = "org.gnome.Loupe.desktop";
      "image/jxrA" = "org.gnome.Loupe.desktop";
      "image/jxrS" = "org.gnome.Loupe.desktop";
      "image/jxs" = "org.gnome.Loupe.desktop";
      "image/jxsc" = "org.gnome.Loupe.desktop";
      "image/jxsi" = "org.gnome.Loupe.desktop";
      "image/jxss" = "org.gnome.Loupe.desktop";
      "image/ktx" = "org.gnome.Loupe.desktop";
      "image/ktx2" = "org.gnome.Loupe.desktop";
      "image/naplps" = "org.gnome.Loupe.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/prs.btif" = "org.gnome.Loupe.desktop";
      "image/prs.pti" = "org.gnome.Loupe.desktop";
      "image/pwg-raster" = "org.gnome.Loupe.desktop";
      "image/qoi" = "org.gnome.Loupe.desktop";
      "image/svg+xml" = "org.gnome.Loupe.desktop";
      "image/svg+xml-compressed" = "org.gnome.Loupe.desktop";
      "image/t38" = "org.gnome.Loupe.desktop";
      "image/tiff" = "org.gnome.Loupe.desktop";
      "image/tiff-fx" = "org.gnome.Loupe.desktop";
      "image/vnd.adobe.photoshop" = "org.gnome.Loupe.desktop";
      "image/vnd.airzip.accelerator.azv" = "org.gnome.Loupe.desktop";
      "image/vnd.blockfact.facti" = "org.gnome.Loupe.desktop";
      "image/vnd.clip" = "org.gnome.Loupe.desktop";
      "image/vnd.cns.inf2" = "org.gnome.Loupe.desktop";
      "image/vnd.dece.graphic" = "org.gnome.Loupe.desktop";
      "image/vnd.djvu" = "org.gnome.Loupe.desktop";
      "image/vnd.dvb.subtitle" = "org.gnome.Loupe.desktop";
      "image/vnd.dwg" = "org.gnome.Loupe.desktop";
      "image/vnd.dxf" = "org.gnome.Loupe.desktop";
      "image/vnd.fastbidsheet" = "org.gnome.Loupe.desktop";
      "image/vnd.fpx" = "org.gnome.Loupe.desktop";
      "image/vnd.fst" = "org.gnome.Loupe.desktop";
      "image/vnd.fujixerox.edmics-mmr" = "org.gnome.Loupe.desktop";
      "image/vnd.fujixerox.edmics-rlc" = "org.gnome.Loupe.desktop";
      "image/vnd.globalgraphics.pgb" = "org.gnome.Loupe.desktop";
      "image/vnd.microsoft.icon" = "org.gnome.Loupe.desktop";
      "image/vnd.mix" = "org.gnome.Loupe.desktop";
      "image/vnd.mozilla.apng" = "org.gnome.Loupe.desktop";
      "image/vnd.ms-modi" = "org.gnome.Loupe.desktop";
      "image/vnd.net-fpx" = "org.gnome.Loupe.desktop";
      "image/vnd.pco.b16" = "org.gnome.Loupe.desktop";
      "image/vnd.radiance" = "org.gnome.Loupe.desktop";
      "image/vnd.sealed.png" = "org.gnome.Loupe.desktop";
      "image/vnd.sealedmedia.softseal.gif" = "org.gnome.Loupe.desktop";
      "image/vnd.sealedmedia.softseal.jpg" = "org.gnome.Loupe.desktop";
      "image/vnd.svf" = "org.gnome.Loupe.desktop";
      "image/vnd.tencent.tap" = "org.gnome.Loupe.desktop";
      "image/vnd.valve.source.texture" = "org.gnome.Loupe.desktop";
      "image/vnd.wap.wbmp" = "org.gnome.Loupe.desktop";
      "image/vnd.xiff" = "org.gnome.Loupe.desktop";
      "image/vnd.zbrush.pcx" = "org.gnome.Loupe.desktop";
      "image/webp" = "org.gnome.Loupe.desktop";
      "image/wmf" = "org.gnome.Loupe.desktop";
      "image/x-3ds" = "org.gnome.Loupe.desktop";
      "image/x-dds" = "org.gnome.Loupe.desktop";
      "image/x-emf" = "org.gnome.Loupe.desktop";
      "image/x-exr" = "org.gnome.Loupe.desktop";
      "image/x-jp2-codestream" = "org.gnome.Loupe.desktop";
      "image/x-portable-anymap" = "org.gnome.Loupe.desktop";
      "image/x-portable-bitmap" = "org.gnome.Loupe.desktop";
      "image/x-portable-graymap" = "org.gnome.Loupe.desktop";
      "image/x-portable-pixmap" = "org.gnome.Loupe.desktop";
      "image/x-qoi" = "org.gnome.Loupe.desktop";
      "image/x-tga" = "org.gnome.Loupe.desktop";
      "image/x-win-bitmap" = "org.gnome.Loupe.desktop";
      "image/x-wmf" = "org.gnome.Loupe.desktop";
      "image/x-xbitmap" = "org.gnome.Loupe.desktop";
      "image/x-xpixmap" = "org.gnome.Loupe.desktop";
    };
  };
}
