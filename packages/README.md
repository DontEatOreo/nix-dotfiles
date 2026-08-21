# Packages

This directory contains the software artifacts maintained by this repository.
Each child directory represents one package and keeps the source, patches, build
definitions, tests, and generated inputs that evolve with it in one place.

## Design intent

- One clear home for each software artifact.
- Package content organized by artifact rather than delivery system.
- The same package available to Nix, Homebrew, BlueBuild, and Ansible.
- Product code and build logic kept separate from machine and user configuration.

## Boundaries

A package produces something installable or runnable. The surrounding delivery
layers decide how that artifact reaches a machine.

Host policy belongs to Ansible, NixOS, or BlueBuild. User configuration belongs
to chezmoi. This directory owns the software those systems consume, not the
configuration of the workstation itself.
