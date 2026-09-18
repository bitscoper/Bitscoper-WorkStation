<div align="center">

# Bitscoper-WorkStation

My NixOS Configuration

[![No AI](https://raw.githubusercontent.com/nuxy/no-ai-badge/master/badge.svg)](https://github.com/bitscoper/Bitscoper-WorkStation#notes)

</div>

## Run

```sh
sudo nix-channel --list

sudo nix-channel --remove nixos

sudo nix-channel --add \
  https://nixos.org/channels/nixos-unstable \
  nixos

sudo nix-channel --list

sudo nix-channel --update && \
  sudo nix-env -u --always

nix-shell -p gitFull \
  --run 'sudo nixos-rebuild boot \
    --refresh --install-bootloader \
    --option experimental-features "nix-command flakes"'
```

## Notes

- I write commit messages in Title Case and past tense, leaving out articles to keep them concise while still showing details.
- I reuploaded the repository to clean up the commit history, but this is unlikely to happen again.
- I later PGP-signed all my commits, so they show a later date.
