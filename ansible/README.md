# Ansible design principles

This directory defines the desired state of a workstation through Ansible. Its purpose
is to make system setup consistent, understandable, and durable across supported
platforms

## What we want

- A declarative model of the system rather than a collection of setup scripts.
- Predictable results across repeated runs and supported platforms.
- Clear boundaries between shared behavior and platform-specific behavior.
- Stable, reproducible behavior based on explicit dependencies.
- Secure handling of sensitive information.
- An architecture built from maintained Ansible capabilities.
- A small and intentional surface area for custom behavior.

## Design direction

The configuration expresses outcomes at the highest practical level. Roles and
other Ansible abstractions organize those outcomes into concepts that remain easy to
understand as the system evolves

Custom behavior represents a deliberate exception for capabilities that Ansible does
not model directly. These exceptions remain contained so the overall design stays
declarative and predictable
