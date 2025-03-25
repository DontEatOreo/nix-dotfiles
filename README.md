# My Nix dotfiles

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

This repo contains my personal dotfiles for NixOS and macOS (Darwin)

If you somehow randomly stumbled upon this repo through a GitHub search or from
my profile and want to find something interesting, here are some files worth
looking at:

## Modules

[system.nix](/hosts/darwin/system.nix) - Here I keep all my macOS system
settings; they're pretty opinionated compared to the macOS defaults, but I think
they're very sensible

[nixcord.nix](/modules/hm/guis/nixcord.nix) - My
[Nixcord](https://github.com/KaylorBen/nixcord) config; it has the Catppuccin
theme and a bunch of QoL (Quality of Life) plugins, making using Discord much
nicer

## Catppuccin

I quite like the Catppuccin theme; it's pretty nice. I would imagine there are
probably "better" themes *(for me)* out there, but I'm not aware of them yet, so
Catppuccin it is!

Unfortunately, individual themes for programs or projects don't have a flake
file *(except for vscode)*, so I made my own custom modules to automate the
creation of the themes. This way, it also allows me to specify the exact theme
and accents I want, and for it to be downstreamd from the catppuccin module

[catppuccin-userstyles.nix](/modules/hm/custom/catppuccin-userstyles.nix) -
Conveniently enough, Catppuccin has their theme for a bunch of sites. I love
consistency, so I think it's a must-have, tbh

[warp-terminal-catppuccin.nix](/modules/hm/custom/warp-terminal-catppuccin.nix) -
Warp Terminal, not much else to say

## Scripts

[yt-dlp-script.sh](/shared/scripts/yt-dlp-script.sh) - A bash script, I have to
download video in my own "niche" format

[update.sh](/modules/update.sh) - A neat bash script
I have to update any custom modules I have *(e.g
[catppuccin-userstyles.nix](/modules/hm/custom/catppuccin-userstyles.n
ix))*

If you want to build my dotfiles, here's how to do it:

### NixOS

```bash
# Override secrets with your own or modify hosts/nixos/users.nix to not use secrets

# Delete my hardware-configuration.nix and create your own one
if [ ! -f "hosts/nixos/hardware-configuration.nix" ]; then
  nixos-generate-config
  mv "hardware-configuration.nix" "hosts/nixos/nyx"
  rm "configuration.nix"
fi

nixos-rebuild switch --use-remote-sudo --flake "/etc/nixos"

# After initial build, you can use the `rebuild` alias
```

### macOS (Darwin)

```bash
nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "$HOME/.nixpkgs"

darwin-rebuild switch --flake "$HOME/.nixpkgs"

# After initial build, you can use the `rebuild` alias
```
