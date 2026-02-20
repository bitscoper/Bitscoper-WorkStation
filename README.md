<div align="center">

# Bitscoper NixOS Configuration

My NixOS Configuration

</div>

## Run

```sh
sudo nix-channel --list

sudo nix-channel --remove nixos

sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos

sudo nix-channel --list

sudo nix-channel --update && sudo sudo nix-env -u --always

nix-shell -p git --run 'sudo nixos-rebuild boot --refresh --install-bootloader --option experimental-features "nix-command flakes"'
```
