# Packages

Each child directory owns one package unit and the inputs that change with it:
source, tests, build metadata, patches, and generated dependency descriptions.
Nix-backed units expose their derivation at the predictable `package.nix`
entry point.

Deployment adapters remain in the conventional roots that consume these
artifacts:

- `overlays/default.nix` registers Nix packages;
- `Formula/` exposes Homebrew formulae;
- `ansible/roles/` installs and configures packages on a host;
- `modules/nixos/` integrates packages into NixOS; and
- `dotfiles/` contains only chezmoi source state destined for the home
  directory.

Configuration that does not produce an artifact belongs to its owning Ansible
role, NixOS module, or chezmoi source tree rather than this directory.

The boundary is deliberately artifact-based rather than tool-based. Do not add
`nix/`, `homebrew/`, or `bluebuild/` subgroups here: one artifact can have more
than one delivery adapter, and those adapters should point back to the same
package unit. Package-specific code belongs here; host policy and home-directory
state do not.

## Units

- `bluebuild-v2`: feature-gated BlueBuild CLI package
- `dotfiles-python`: shared workstation commands
- `equicord-settings`: generated Equicord settings and Black Rose Doll CSS
- `fido-phone`: packaged macOS helper and private Android receiver
- `ghidra-mcp`: combined Ghidra MCP service package
- `ghostty-patched`: patched Ghostty build and shared patch series
- `hyper-window-tiling`: GNOME and KDE window-tiling extensions
- `jj-patched`: patch series consumed by the Homebrew formula
- `terminal-theme-tools`: theme-aware launcher and C API
- `uresourced`: pinned uresourced package
