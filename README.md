# My Nix dotfiles

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)

This repo contains my main dotfiles for [nix-darwin](https://github.com/LnL7/nix-darwin) and [NixOS](https://nixos.org)

## Scope

[/shared/](/shared/) folder mainly contains CLI tools shared between macOS and NixOS

[/home-manager/](/home-manager/) is shared between macOS and NixOS with the exception of the Linux folder

[/hosts/](/hosts/) contains all the system configurations for macOS and NixOS

## How to Use

To use this configuration, follow the steps below:

### NixOS

```bash
# Navigate to /etc/nix/nixos
cd "/etc/nix/nixos"

# Clone the repo
git clone "https://github.com/DontEatOreo/nix-dotfiles.git"

# Generate hardware-configuration.nix with `nixos-generate-config`
nixos-generate-config
# Then move hardware-configuration.nix to hosts/nixos/users/nyx
mv "hardware-configuration.nix" "hosts/nixos/users/nyx"
# Delete configuration.nix
rm "configuration.nix"

# Apply the configuration
sudo nixos-rebuild switch --flake "/etc/nix/nixos"

# Alternatively, you can also use the `rebuild` alias...
```

### macOS

```bash
# Installed Nix & Homebrew first
# Nix
sh <(curl -L https://nixos.org/nix/install)
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Navigate to the ~/.nixpkgs directory
cd "$HOME/.nixpkgs"

# Clone the repository
git clone "https://github.com/DontEatOreo/nix-dotfiles.git"

# Since the config is flake-based, we will need to temporarily do it the verbose way
nix --experimental-features 'nix-command flakes' run nix-darwin -- switch --flake "$HOME/.nixpkgs"

# After the first building we can return back to using the normal command
darwin-rebuild switch --flake "$HOME/.nixpkgs"

# Alternatively, you can also use the `rebuild` alias...
```

## Notes

- If you end up getting an error of the sort of `error: cached failure of attribute` make sure to pass the option `--option eval-cache false` to `nix run`
- TeX packages are disabled by default due to the file size
- Special thanks to [@ashuramaruzxc](https://github.com/ashuramaruzxc) for bash & zsh aliases, PS1 and `commonAttrs`.
