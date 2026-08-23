# Ansible design principles

This directory is the mutable integration layer for a workstation. Spectrum's static
Linux state belongs to BlueBuild, ordinary programs belong to Homebrew, and home files
belong to chezmoi. Ansible handles the remaining state that depends on a user account,
live hardware, credentials, or an already-running desktop session

## What we want

- A declarative model of the system rather than a collection of setup scripts.
- Predictable results across repeated runs and supported platforms.
- Clear boundaries between shared behavior and platform-specific behavior.
- Stable, reproducible behavior based on explicit dependencies.
- Secure handling of sensitive information.
- An architecture built from maintained Ansible capabilities.
- A small and intentional surface area for custom behavior.
- No duplication of files, packages, or systemd enablement already owned by the
  Spectrum image or Brewfile.
- Application launchers and generated home-directory settings belong to chezmoi
  when they can be reconciled without host privileges or live hardware facts.

## Design direction

The configuration expresses outcomes at the highest practical level. Roles and
other Ansible abstractions organize those outcomes into concepts that remain easy to
understand as the system evolves

Custom behavior represents a deliberate exception for capabilities that Ansible does
not model directly. These exceptions remain contained so the overall design stays
declarative and predictable

Before adding a Linux task, prefer the following ownership order: BlueBuild for
immutable host state, Homebrew for programs, chezmoi for home files, and Ansible only
for machine-local reconciliation that cannot be expressed by those layers
