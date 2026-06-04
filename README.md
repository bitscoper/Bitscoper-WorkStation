<div align="center">

# Bitscoper NixOS Configuration

My NixOS Configuration

</div>

## Stack

### Base

- **Kernel:** Linux XanMod
- **Bootloader:** GRUB
- **Boot and Shutdown Splash:** Plymouth
- **Display Protocol:** Wayland
- **Display Manager:** Simple Desktop Display Manager (SDDM)
- **Compositor:** Hyprland

### Multimedia

- **Word Processor, Spreadsheet, and Presentation Editor:** OnlyOffice
- **PDF Editor:** OnlyOffice, PDF Arranger
- **PDF Viewer:** Sioyek, Brave
- **UVC Capture Viewer:** Guvcview
- **QR Code Generator:** CoBang
- **Vector Graphics Editor:** Inkscape
- **Raster Image Editor:** GNU Image Manipulation Program (GIMP)
- **Raw Image Developer:** Darktable
- **Audio Recorder and Editor:** Audacity
- **Music Tag Editor:** MusicBrainz Picard
- **Video Editor and Animator:** Blender
- **Image Format Converter:** Switcheroo
- **Image Compressor:** Curtail
- **Video Compressor:** Constrict
- **Image Viewer:** gThumb
- **Media Player:** VLC

### 2D Fabrication

- **Cutter / Plotter Host:** Inkcut

### 3D Fabrication

- **Parametric CAD:** FreeCAD
- **Organic Modeller:** Blender
- **Mesh Processor:** MeshLab
- **STL Viewer:** fstl
- **FDM Slicer:** OrcaSlicer
- **MSLA Resin Slicer:** mslicer
- **Printer Host:** Printrun (Includes Pronterface)

## Run

```sh
sudo nix-channel --list

sudo nix-channel --remove nixos

sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos

sudo nix-channel --list

sudo nix-channel --update && sudo sudo nix-env -u --always

nix-shell -p git --run 'sudo nixos-rebuild boot --refresh --install-bootloader --option experimental-features "nix-command flakes"'
```

## Notes

- I write commit messages in Title Case and past tense, leaving out articles to keep them concise while still showing details.
- I reuploaded the repository to clean up the commit history, but this is unlikely to happen again.
