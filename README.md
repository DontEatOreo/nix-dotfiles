# dotfiles 🌹🎀

My personal workstation config for Spectrum/Bluefin, NixOS, and macOS

> [!IMPORTANT]
> This repository is for my machines. It's public for reference, but it isn't a reusable
> installer or a supported project

<p align="center">
  <img src=".github/assets/readme-hero.svg" width="72%">
</p>

The goal is to make every machine feel like mine without maintaining the same config
four times

## Rebuilding a machine

I keep the repo at `~/dotfiles`:

```bash
git clone https://github.com/4evy/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

<details>
<summary><strong>Spectrum / Bluefin</strong></summary>

<br>

On a fresh Bluefin install, I switch to the Spectrum image:

```bash
sudo bootc switch ghcr.io/4evy/spectrum:latest
systemctl reboot
```

After the reboot, I finish the setup:

```bash
cd ~/dotfiles
just setup
```

</details>

<details>
<summary><strong>NixOS</strong></summary>

<br>

On an installed NixOS system, I apply the flake and finish the shared setup:

```bash
sudo nixos-rebuild \
  --option extra-substituters https://install.determinate.systems \
  --option extra-trusted-public-keys cache.flakehub.com-3:hJuILl5sVK4iKm86JzgdXW12Y2Hwd5G07qKtHTOcDCM= \
  --flake .#nixos \
  switch
just setup
```

The extra cache options are only needed for the first rebuild. Afterward, this shorter
command is enough:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

</details>

<details>
<summary><strong>macOS</strong></summary>

<br>

This path needs macOS 26 or newer. From the cloned repo, I run:

```bash
./ansible/bootstrap.sh --setup
```

The script bootstraps Homebrew and Ansible, installs the userland, applies the dotfiles,
and configures the Mac. It asks for administrator and 1Password access when needed

I can exercise the same flow with disposable fake tools without changing the host:

```bash
just bootstrap-simulate
```

I pass a scenario such as `apply-failure` to test the unhappy path

</details>

## Commands

`just` or `just --list` shows every recipe

<details>
<summary><strong>Everyday commands</strong></summary>

<br>

```bash
just setup               # Bootstrap and apply everything
just update              # Update userland, dotfiles, and host setup
just dotfiles-diff       # Preview pending chezmoi changes
just apply               # Apply chezmoi dotfiles only
just status              # Show Spectrum image status
just determinate-status  # Show Determinate version, features, and daemon state
just determinate-upgrade # Upgrade installer-managed Determinate Nix

just spectrum-validate   # Validate the BlueBuild recipe and base digest
just spectrum-build      # Build Spectrum locally
just spectrum-inspect    # Inspect and test the local image

just fmt                 # Format the repository
just lint                # Run static checks
just check               # Run the full validation suite
```

For direct Nix work, drop down a level:

```bash
nix develop
nix flake check
```

</details>

## License

[MIT](LICENSE)
