<div align="center">

# Bitscoper-WorkStation

My NixOS Configuration

</div>

## Stack

### Base

- **Kernel:** Linux XanMod

&nbsp;

- **Bootloader:** GRUB
- **Boot and Shutdown Splash:** Plymouth

&nbsp;

- **Display Protocol:** Wayland
- **Display Manager:** Simple Desktop Display Manager (SDDM)
- **Compositor:** Hyprland

### Multimedia

- **Word Processor, Spreadsheet, and Presentation Editor:** OnlyOffice
- **PDF Editor:** OnlyOffice, PDF Arranger
- **PDF Viewer:** Evince, Cromite

&nbsp;

- **UVC Capture Viewer:** Guvcview
- **QR Code Generator:** CoBang

&nbsp;

- **Vector Graphics Editor:** Inkscape
- **Raster Image Editor:** GNU Image Manipulation Program (GIMP)
- **Raw Image Developer:** Darktable

&nbsp;

- **Audio Recorder and Editor:** Audacity
- **Music Tag Editor:** MusicBrainz Picard

&nbsp;

- **Video Editor and Animator:** Blender

&nbsp;

- **Image Format Converter:** Switcheroo

&nbsp;

- **Image Compressor:** Curtail
- **Video Compressor:** Constrict

&nbsp;

- **Image Viewer:** gThumb
- **Audio Player:** Nocturne
- **Video Player:** Clapper

### 2D Fabrication

- **Cutter / Plotter Host:** Inkcut

### 3D Fabrication

- **Parametric CAD:** FreeCAD
- **Organic Modeller:** Blender

&nbsp;

- **Mesh Processor:** MeshLab

&nbsp;

- **STL Viewer:** fstl

&nbsp;

- **FDM Slicer:** OrcaSlicer
- **MSLA Resin Slicer:** mslicer

&nbsp;

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
