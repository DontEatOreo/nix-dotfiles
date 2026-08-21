# Spectrum

This directory defines Spectrum, our Bluefin-based machine image and non-NixOS Linux
distribution

Spectrum combines BlueBuild for the operating-system image, Ansible for mutable host
configuration, Homebrew for programs, and chezmoi for the user environment. Nix is
installed, but it is not used as a general program manager

The Nix profile is limited to tools that support Nix development itself:

- `deadnix`
- `nh`
- `nil`
- `nix-instantiate`
- `nom`
- `nix-tree`
- `nixd`
- `nixfmt`

Everyday applications and workstation features remain outside Nix. Nix is available
for repository development and on-demand project outputs without becoming the owner of
the machine
