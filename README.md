# dotfiles 🌹🎀

Personal Spectrum/Bluefin, NixOS, and macOS workstation configuration, built
with Homebrew, Nix, Ansible, and chezmoi.

<p>
  <a href="https://github.com/4evy/dotfiles/pkgs/container/spectrum"><img alt="GHCR Spectrum image" src="https://img.shields.io/badge/GHCR-spectrum-ce98a5?style=flat-square&logo=github&logoColor=ce98a5&labelColor=110e17"></a>
</p>

<p>
  <a href="https://projectbluefin.io"><img alt="Bluefin" src="https://img.shields.io/badge/Bluefin-ce98a5?style=flat-square&logo=fedora&logoColor=ce98a5&labelColor=110e17"></a>
  <a href="https://nixos.org"><img alt="NixOS" src="https://img.shields.io/badge/NixOS-ce98a5?style=flat-square&logo=nixos&logoColor=ce98a5&labelColor=110e17"></a>
  <a href="https://www.apple.com/macos"><img alt="macOS" src="https://img.shields.io/badge/macOS-ce98a5?style=flat-square&logo=apple&logoColor=ce98a5&labelColor=110e17"></a>
</p>

<p>
  <a href="https://brew.sh"><img alt="Homebrew" src="https://img.shields.io/badge/Homebrew-ce98a5?style=flat-square&logo=homebrew&logoColor=ce98a5&labelColor=110e17"></a>
  <a href="https://www.chezmoi.io"><img alt="chezmoi" src="https://img.shields.io/badge/chezmoi-ce98a5?style=flat-square&logo=homeassistant&logoColor=ce98a5&labelColor=110e17"></a>
  <a href="https://www.ansible.com"><img alt="Ansible" src="https://img.shields.io/badge/Ansible-ce98a5?style=flat-square&logo=ansible&logoColor=ce98a5&labelColor=110e17"></a>
  <img alt="Black Rose Doll light and dark theme" src="https://img.shields.io/badge/Theme-Black%20Rose%20Doll-ce98a5?style=flat-square&labelColor=110e17">
</p>

> [!IMPORTANT]
> This is my personal setup. It is public for reference, not a universal installer.

## What's here

- **Spectrum / Bluefin:** custom bootc image and desktop setup
- **NixOS:** declarative system and user configuration
- **Apple Silicon macOS:** Homebrew and Ansible bootstrap
- **Everywhere:** shared dotfiles managed by chezmoi

## Setup

Clone the repository first:

```bash
git clone https://github.com/4evy/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Spectrum / Bluefin

From a fresh Bluefin install:

```bash
sudo bootc switch ghcr.io/4evy/spectrum:latest
systemctl reboot
```

After rebooting:

```bash
cd ~/dotfiles
just setup
```

### NixOS

From an installed NixOS system:

```bash
sudo nixos-rebuild \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= \
  --flake .#nixos \
  switch
just setup
```

Toshy uses one pinned upstream release on both system families. On NixOS the
rebuild installs Toshy's native system module and Nix runtime, then `just setup`
installs the matching user files. On other Linux systems `just setup` runs the
matching upstream installer directly. Keep that order after a Toshy pin update;
provisioning rejects a Nix runtime and user-files revision mismatch.

The extra cache options are only needed for the first rebuild. Later rebuilds
can use:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

### Apple Silicon macOS

Requires macOS 26 or newer. From the cloned repository, run:

```bash
./ansible/bootstrap.sh --setup
```

This bootstraps Homebrew and Ansible, installs the complete userland, applies
the dotfiles, and configures the host. It prompts for administrator and
1Password access when needed.

Exercise the same flow against disposable fake tools without changing the host:

```bash
just bootstrap-simulate
```

Pass a scenario such as `apply-failure` to test error handling.

## Everyday commands

Run `just` or `just --list` for the complete recipe list.

```bash
just setup          # Bootstrap and apply everything
just update         # Update userland, dotfiles, and host setup
just dotfiles-diff  # Preview pending chezmoi changes
just apply          # Apply chezmoi dotfiles only
just status         # Show Spectrum image status

just spectrum-validate # Validate the BlueBuild recipe and base digest
just spectrum-build    # Build Spectrum locally
just spectrum-inspect  # Inspect and test the local image

just fmt            # Format the repository
just lint           # Run static checks
just check          # Run the full validation suite
```

For direct Nix work:

```bash
nix develop
nix flake check
nix run .#ghidra-mcp
```

## License

[LICENSE](LICENSE)
