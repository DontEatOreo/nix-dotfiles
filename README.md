# My dotfiles

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

This repository contains my personal configuration files for [nix-darwin](https://github.com/LnL7/nix-darwin) and [NixOS](https://nixos.org)

## Scope

To start with, all CLI tools are located in [/shared](/shared/) and are *shared* between macOS and NixOS. For macOS, GUI programs are mainly managed by homebrew, except for vscode, which is managed by `home-manager` and is shared between macOS and NixOS. For NixOS, all GUI programs are managed by home-manager.

All macOS system settings are managed by [system.nix](/hosts/darwin/users/anon/system.nix)

## How to Use

To use this configuration, follow the steps below:

### NixOS

```bash
# Navigate to /etc/nix/nixos
cd /etc/nix/nixos

# Clone the repository
git clone https://github.com/DontEatOreo/dotfiles.git

# Generate hardware-configuration.nix with `nixos-generate-config`
nixos-generate-config
# Then move hardware-configuration.nix to hosts/nixos/users/nyx
mv hardware-configuration.nix hosts/nixos/users/nyx
# Delete configuration.nix
rm configuration.nix

# Apply the configuration
sudo nixos-rebuild switch --flake .
```

### macOS

```bash
# Installed Nix & Homebrew first
# Nix
sh <(curl -L https://nixos.org/nix/install)
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Navigate to the ~/.nixpkgs directory
cd ~/.nixpkgs

# Clone the repository
git clone https://github.com/DontEatOreo/dotfiles.git

# Install Nix Darwin
nix run nix-darwin -- switch --flake .

# For future apply the configuration
darwin-rebuild switch --flake .
```

## Notes

- TeX packages are disabled by default due to the file size
- Special thanks to @ashuramaruzxc for bash & zsh aliases, PS1 and `commonAttrs`.
