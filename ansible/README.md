# Ansible design principles

This directory is the mutable integration layer for a workstation. Spectrum's
static Linux state belongs to BlueBuild, ordinary programs belong to Homebrew,
and home files belong to chezmoi. Ansible handles the remaining state that
depends on a user account, live hardware, credentials, or an already-running
desktop session

## What we want

- A declarative model of the system rather than a collection of setup scripts.
- Predictable results across repeated runs and supported platforms.
- Clear boundaries between shared behavior and platform-specific behavior.
- Stable, reproducible behavior based on explicit dependencies.
- Secure handling of sensitive information.
- An architecture built from maintained Ansible capabilities.
- A small and intentional surface area for custom behavior.
- No duplication of files, packages, or systemd enablement already owned by
  the Spectrum image or Brewfile.
- No source builds for software that BlueBuild or a package manager can
  reconcile directly.
- Application launchers and generated home-directory settings belong to
  chezmoi when they can be reconciled without host privileges or live hardware
  facts.

## Design direction

The configuration expresses outcomes at the highest practical level. Roles and
other Ansible abstractions organize those outcomes into concepts that remain
easy to understand as the system evolves

Custom behavior represents a deliberate exception for capabilities that
Ansible does not model directly. These exceptions remain contained so the
overall design stays declarative and predictable

Before adding a Linux task, prefer the following ownership order: BlueBuild
for immutable host state, Homebrew for programs, chezmoi for home files, and
Ansible only for machine-local reconciliation that cannot be expressed by
those layers

Normal setup runs install missing Brewfile entries without upgrading the
existing userland. `just update` opts into Homebrew Bundle upgrades explicitly

Ansible modules are the default for that remaining state. A custom module is
justified only when no maintained module or composition of modules can model
the outcome, and the exception must support check mode

## Maintained collection capabilities

The playbook uses maintained collection plugins for the mutable state they
model directly:

- `community.general` owns dconf and KDE settings, macOS defaults and launchd
  services, Homebrew casks and services, INI edits, kernel module loading, and
  1Password lookups.
- `community.sops.load_vars` reads encrypted application settings without
  materializing plaintext files.
- `ansible.posix.synchronize` performs the file-tree reconciliations that need
  rsync semantics.

There is no Ansible package-install layer for Linux. Spectrum packages,
Flatpaks, fonts, extensions, and enabled system services belong to BlueBuild;
portable programs and editor extensions belong to the Brewfile.

## Intentional custom modules

- `dotfiles_codesign` treats signing-identity creation and application signing
  as one idempotent macOS operation.
- `dotfiles_selinux_service` compares locally built policy with installed
  policy and defers unsafe service restarts, including active Tailscale SSH
  sessions.
