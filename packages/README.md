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

## Patch queues

Patched packages keep a [Quilt](https://savannah.nongnu.org/projects/quilt/)
queue in `patches/`: numbered unified diffs and the `series` file that defines
their order. Start a queue workspace from the exact npins source used by package
builds; the command copies that source to a writable temporary directory,
applies the full queue, and opens an interactive shell there:

```sh
just quilt-shell kanata-with-cmd
```

To add a change, create a patch, register files before editing them, and refresh
the patch afterward:

```sh
quilt new 0002-short-description.patch
quilt add path/to/file
# Edit the registered files.
quilt refresh
```

Use `quilt pop -a` to return the checkout to the pinned source. `quilt series`,
`quilt applied`, and `quilt unapplied` show the queue state. Quilt owns the
`series` file; package definitions consume it rather than maintaining a second
patch list. Keep that file boring: exactly one `.patch` basename per line, with
no blank lines, comments, guards, or options. This lets Git, Homebrew, Nix, and
the image build consume it without their own Quilt parsers.

The managed `~/.quiltrc` produces sorted, timestamp-free `a/` and `b/` patches,
refreshes their diffstats, omits Git blob indexes, and includes function context
in hunk headers. Check that every patch still applies and is fully refreshed
against its pin with:

```sh
just quilt-check
```

The Quilt workspace is disposable but deliberately retained after its shell
exits, so unrefreshed source edits are not destroyed. Its path is printed when
the shell starts and exits.
