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
`ghcr.io/4evy/spectrum:latest-cache`. Pull-request builds stay read-only while importing
that registry cache and using a branch-aware GitHub Actions layer cache, so they reuse
work without pushing test images.

The top-level recipe is intentionally only an assembly manifest. Expensive build
stages live under `recipes/spectrum/stages`, while main-image modules are ordered under
`recipes/spectrum/modules` from remote-heavy software installation to local files,
system policy, and final assertions. This ordering means edits to local configuration
do not invalidate package, font, extension, or Linuxbrew layers.

Astral and Ghostty consume minimal source-lock projections under
`recipes/spectrum/sources` instead of the repository-wide npins lock. Consequently, an
unrelated source update does not invalidate either builder stage. `just source-update`
refreshes these projections, and `just spectrum-validate` rejects any drift from
`npins/sources.json`. The Ghostty stage also mounts persistent global and local Zig
caches, allowing compilation artifacts to survive a source or patch cache miss.

The repository-local Hyper window tiler is also built once in a pinned Bun stage and
copied into the system GNOME and KWin extension directories. Per-user Ansible work is
therefore limited to enabling the extension and setting desktop shortcuts.

The pinned Kanata executable, configuration, device policy, and system service are
built into the image together. Ansible only reconciles the live user's device-group
membership, disables a conflicting remapper when requested, and starts the service.

Homebrew owns portable userland payloads that do not need to be frozen into the image,
including Helium, its profile configurer, Equilotl, and the repository-pinned
`yt-dlp-script`. Chezmoi owns
their user launchers and post-install reconciliation; Ansible no longer downloads
those programs itself.
