<div align="center">

# Bitscoper-WorkStation

My NixOS Configuration

[![No AI](https://raw.githubusercontent.com/nuxy/no-ai-badge/master/badge.svg)](#notes)

</div>

## Details

### Modules

- AppImage
- Avahi
- bat
- BlueZ
- brightnessctl
- Btrfs
- chrony
- Cine
- cliphist
- Cockpit
- Contour
- CPU-X
- Curtail
- D-Bus
- direnv
- Evince
- Exhibit
- Fastfetch
- Fcitx 5
- fdroidcl
- FFmpeg
- Firefox
- Flutter
- fprintd
- fwupd
- Git
- GNOME Keyring
- GNU Bash
- GNU GRand Unified Bootloader
- GnuPG
- GPSd
- GStreamer
- GTK
- Hardinfo2
- hypridle
- Hyprland
- hyprlock
- hyprpaper
- Hyprshot
- I2C
- Icecast
- ImHex
- Jellyfin
- KeePassXC
- Kubernetes
- LibreOffice
- libvirt
- Loupe
- Lutris
- MariaDB
- Nautilus
- NetworkManager
- nix-index
- Nocturne
- nwg-bar
- nwg-drawer
- Ollama
- Open Broadcaster Software Studio
- OpenCode
- OpenDM
- OpenSSH
- PeaZip
- PHP
- PipeWire
- Playerctl
- Plymouth
- Podman
- polkit
- PostgreSQL
- qBittorrent
- Qt
- Resources
- Rofi
- rtl-sdr
- Simple Desktop Display Manager
- Starship
- Sudo
- SwayNotificationCenter
- sysctl
- Syshud
- systemd
- Tailscale
- Tor
- udev
- udiskie
- Ungoogled Chromium
- Universal Wayland Session Manager
- vivid
- Waybar
- Waydroid
- Wayscriber
- WayVNC
- Wireshark
- xdg-desktop-portal-gtk
- XDG
- Zed

### Hardware Specific Modules

- ASUS VivoBook X415EA
- Fantech EOS Lite GP15L Multi-Platform Gamepad
- SDDPNQD-512G-1102

## Run

```sh
sudo nix-channel --list

sudo nix-channel --remove nixos

sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos

sudo nix-channel --list

sudo nix-channel --update && sudo nix-env -u --always

nix-shell -p gitFull --run 'sudo nixos-rebuild boot --install-bootloader --option experimental-features "nix-command flakes" --refresh --upgrade-all --max-jobs=1'
```

## Notes

- I only use AI to search for alternatives and possibilities during brainstorming. AI-generated code from contributors is also not allowed.
- I commit multiple changes in a single commit.
- I write commit messages in Title Case and past tense, leaving out articles to keep them concise while still showing details.
- I previously reuploaded the repository to clean up the commit history and later deleted some commits.
- I later [PGP](https://github.com/bitscoper/bitscoper#pgp-public-key)-signed all my commits, so they show later dates.
