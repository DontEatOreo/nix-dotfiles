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

## BlueBuild CLI and build flow

Spectrum includes the BlueBuild CLI at `/usr/bin/bluebuild`, together with Podman and
the other runtime tools it needs to build images. The embedded CLI is pinned to the
same upstream commit as the `bluebuild-cli` entry in `npins/sources.json`; this keeps
the feature-gated recipe-v2 parser used by Spectrum available inside the installed OS.
`just spectrum-validate` rejects the recipe if those pins drift apart.

Use `just spectrum-stage` to build the local image and run the bootc, Ghostty, and
embedded BlueBuild checks against it. The lower-level `just spectrum-build` and
`just spectrum-inspect` commands remain available when only one phase is needed.

BlueBuild supplies locked package-manager cache mounts to every module. Local Podman
builds reuse those mounts and unchanged image layers. Published CI builds additionally
set `BB_CACHE_LAYERS=true`, which imports and exports the registry cache at
`ghcr.io/4evy/spectrum:latest-cache`; pull-request builds stay read-only and therefore
use only the current runner's local cache.
