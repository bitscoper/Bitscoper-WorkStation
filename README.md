<div align="center">

# Bitscoper-WorkStation

My NixOS Configuration

[![No AI](https://raw.githubusercontent.com/nuxy/no-ai-badge/master/badge.svg)](#notes)

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

- I only use AI to search for alternatives and possibilities during brainstorming. AI-generated code from contributors is also not allowed.
- I commit multiple changes in a single commit.
- I write commit messages in Title Case and past tense, leaving out articles to keep them concise while still showing details.
- I previously reuploaded the repository to clean up the commit history and later deleted some commits.
- I later [PGP](https://github.com/bitscoper/bitscoper#pgp-public-key)-signed all my commits, so they show later dates.
