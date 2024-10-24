# My Nix dotfiles

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

This repo contains my main dotfiles for [nix-darwin](https://github.com/LnL7/nix-darwin) and [NixOS](https://nixos.org)

## Scope

[/shared/](/shared/) folder mainly contains CLI tools shared between macOS and NixOS

---

[/modules/](/modules/) is the module folder that contains modules for both macOS and NixOS.

The `common` folder contains modules that are at the `nix/darwin` system level and share very similar or the same settings (e.g., `nix` and `nixpkgs`).

The `de` folder contains `Desktop Environments` modules only meant for NixOS. The `home-manager` folder contains all the Home Manager modules, which are shared between macOS and NixOS.

---

[/hosts/](/hosts/) contains all the system configurations for macOS and NixOS

---

## How to Use

To use this configuration, follow the steps below:

### NixOS

```bash
# Backup the existing NixOS dotfiles
if [ -d "/etc/nix/nixos" ]; then
  sudo mkdir -p "/etc/nixos-backup"
  sudo mv "/etc/nix/nixos" "/etc/nixos-backup/"
fi

if [ ! -d "/etc/nixos" ]; then 
    sudo mkdir -p "/etc/nixos" 
fi
sudo chown -R "$USER" "/etc/nixos/"

# Clone the repo
git clone "https://github.com/DontEatOreo/nix-dotfiles.git" "/tmp/nix-dotfiles"

# Move files over
sudo mv "/tmp/nix-dotfiles" "/etc/nixos"

cd "/etc/nixos/"

# Generate the hardware configuration
if [ ! -f "hosts/nixos/hardware-configuration.nix" ]; then
  nixos-generate-config
  mv "hardware-configuration.nix" "hosts/nixos/nyx"
  rm "configuration.nix"
fi

nixos-rebuild switch --use-remote-sudo --flake "/etc/nixos"

# Or you can also use `rebuild` alias after the initial build
```

### macOS

```bash
if [ -d "$HOME/.nixpkgs" ]; then
  sudo mkdir -p "$HOME/.nixpkgs-backup/"
  sudo mv "$HOME/.nixpkgs" "$HOME/.nixpkgs-backup/"
fi

# Clone the repo
git clone "https://github.com/DontEatOreo/nix-dotfiles.git" "$HOME"

if [! -d "$HOME/.nixpkgs" ]; then 
    mkdir -p "$HOME/.nixpkgs"
if
mv "$HOME/nix-dotfiles" "$HOME/.nixpkgs"

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Since the config is flake-based, we will need to temporarily do it the verbose way
nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "$HOME/.nixpkgs"

# After the first build, we can return to using the normal command
darwin-rebuild switch --flake "$HOME/.nixpkgs"

# Or you can also use `rebuild` alias after the initial build
```

## Notes

- If you end up getting an error of the sort of `error: cached failure of attribute` make sure to pass the option `--option eval-cache false` to `nix run`
- Special thanks to [@ashuramaruzxc](https://github.com/ashuramaruzxc) for bash & zsh aliases, PS1 and `commonAttrs`.
