#!/usr/bin/python
"""Manage exact NVIDIA Flatpak extension runtimes for one installation scope."""

from __future__ import annotations

import re
from collections.abc import Callable, Iterable, Sequence
from dataclasses import asdict, dataclass

try:
    from ansible.module_utils.basic import (  # ty: ignore[unresolved-import]
        AnsibleModule,
    )
except ModuleNotFoundError:
    AnsibleModule = None  # type: ignore[assignment,misc]

DOCUMENTATION = r"""
---
module: dotfiles_flatpak_nvidia
short_description: Manage exact NVIDIA Flatpak extension runtimes
description:
  - Discovers the active NVIDIA GL driver extensions and available NVIDIA VA-API branches.
  - Installs exact runtime references for either the user or system Flatpak installation.
  - Uses the exact branch and native architecture when deciding whether a runtime is present.
author: 4evy
options:
  scope:
    description: Flatpak installation scope to reconcile.
    choices: [user, system]
    required: true
    type: str
  remote:
    description: Flatpak remote providing the runtime extensions.
    default: flathub
    type: str
"""

EXAMPLES = r"""
- name: Install exact user NVIDIA Flatpak runtimes
  dotfiles_flatpak_nvidia:
    scope: user

- name: Install exact system NVIDIA Flatpak runtimes
  dotfiles_flatpak_nvidia:
    scope: system
  become: true
"""

RETURN = r"""
architecture:
  description: Native Flatpak architecture used in exact active paths.
  returned: always
  type: str
required:
  description: Exact runtime references required for the selected scope.
  returned: always
  type: list
  elements: str
missing:
  description: Required references that were absent before reconciliation.
  returned: always
  type: list
  elements: str
installed:
  description: Runtime references installed by this invocation.
  returned: always
  type: list
  elements: str
remote_available:
  description: Whether the selected scope has the requested Flatpak remote.
  returned: always
  type: bool
"""

REFERENCE_PATTERN = re.compile(r"^[A-Za-z0-9._-]+//[A-Za-z0-9._-]+$")
VAAPI_PATTERN = re.compile(
    r"^org[.]freedesktop[.]Platform[.]VAAPI[.]nvidia[ \t]+(?P<branch>\S+)$",
)


@dataclass(frozen=True)
class CommandResult:
    returncode: int
    stdout: str
    stderr: str = ""


@dataclass(frozen=True)
class ScopeConfig:
    executable: str
    scope: str
    remote: str = "flathub"


@dataclass(frozen=True)
class ScopeState:
    architecture: str
    remote_available: bool
    required: tuple[str, ...]
    missing: tuple[str, ...]


Runner = Callable[[Sequence[str]], CommandResult]


def unique(items: Iterable[str]) -> tuple[str, ...]:
    """Return items in first-seen order without duplicates."""
    return tuple(dict.fromkeys(items))


def gl_runtime_references(output: str) -> tuple[str, ...]:
    """Convert active NVIDIA GL driver names to exact Flatpak references."""
    return unique(
        f"org.freedesktop.Platform.GL.{driver}//1.4"
        for driver in output.splitlines()
        if driver.startswith("nvidia-")
    )


def vaapi_runtime_references(output: str) -> tuple[str, ...]:
    """Convert remote NVIDIA VA-API rows to exact Flatpak references."""
    references: list[str] = []
    for line in output.splitlines():
        match = VAAPI_PATTERN.fullmatch(line.strip())
        if match:
            references.append(
                f"org.freedesktop.Platform.VAAPI.nvidia//{match.group('branch')}",
            )
    return unique(tuple(references))


def split_reference(reference: str) -> tuple[str, str]:
    """Validate and split an exact application//branch reference."""
    if not REFERENCE_PATTERN.fullmatch(reference):
        msg = f"malformed Flatpak runtime reference: {reference}"
        raise ValueError(msg)
    application, branch = reference.split("//", maxsplit=1)
    return application, branch


def inspect_scope(
    config: ScopeConfig,
    run: Runner,
) -> ScopeState:
    """Discover exact required and missing runtimes without changing state."""
    architecture_result = run((config.executable, "--default-arch"))
    architecture = architecture_result.stdout.strip()
    if architecture_result.returncode != 0 or not architecture:
        msg = architecture_result.stderr.strip() or "Flatpak returned no architecture"
        raise RuntimeError(msg)

    drivers_result = run((config.executable, "--gl-drivers"))
    gl_references = (
        gl_runtime_references(drivers_result.stdout)
        if drivers_result.returncode == 0
        else ()
    )

    remotes_result = run(
        (
            config.executable,
            "remotes",
            f"--{config.scope}",
            "--columns=name",
        ),
    )
    remotes = (
        set(remotes_result.stdout.splitlines())
        if remotes_result.returncode == 0
        else set()
    )
    remote_available = config.remote in remotes
    if not remote_available:
        return ScopeState(
            architecture=architecture,
            remote_available=False,
            required=(),
            missing=(),
        )

    runtimes_result = run(
        (
            config.executable,
            "remote-ls",
            f"--{config.scope}",
            config.remote,
            "--runtime",
            "--columns=application,branch",
        ),
    )
    vaapi_references = (
        vaapi_runtime_references(runtimes_result.stdout)
        if runtimes_result.returncode == 0
        else ()
    )
    required = unique((*gl_references, *vaapi_references))
    missing: list[str] = []
    for reference in required:
        application, branch = split_reference(reference)
        installed = run(
            (
                config.executable,
                "info",
                f"--{config.scope}",
                f"--arch={architecture}",
                application,
                branch,
            ),
        )
        if installed.returncode != 0:
            missing.append(reference)
    return ScopeState(
        architecture=architecture,
        remote_available=True,
        required=required,
        missing=tuple(missing),
    )


def install_missing(
    config: ScopeConfig,
    state: ScopeState,
    run: Runner,
    *,
    check_mode: bool,
) -> tuple[str, ...]:
    """Install missing exact references, or report them in check mode."""
    if check_mode:
        return ()
    installed: list[str] = []
    for reference in state.missing:
        result = run(
            (
                config.executable,
                "install",
                f"--{config.scope}",
                "--noninteractive",
                config.remote,
                reference,
            ),
        )
        if result.returncode != 0:
            message = result.stderr.strip() or result.stdout.strip()
            msg = f"failed to install {reference}: {message}"
            raise RuntimeError(msg)
        installed.append(reference)
    return tuple(installed)


def main() -> None:
    """Ansible module entry point."""
    if AnsibleModule is None:
        raise RuntimeError("Ansible is required to execute this module")
    module = AnsibleModule(
        argument_spec={
            "scope": {
                "type": "str",
                "required": True,
                "choices": ("user", "system"),
            },
            "remote": {"type": "str", "default": "flathub"},
        },
        supports_check_mode=True,
    )
    executable = module.get_bin_path("flatpak", required=True)
    config = ScopeConfig(
        executable=executable,
        scope=module.params["scope"],
        remote=module.params["remote"],
    )

    def run(argv: Sequence[str]) -> CommandResult:
        returncode, stdout, stderr = module.run_command(list(argv))
        return CommandResult(returncode, stdout, stderr)

    try:
        state = inspect_scope(config, run)
        installed = install_missing(
            config,
            state,
            run,
            check_mode=module.check_mode,
        )
    except (RuntimeError, ValueError) as error:
        module.fail_json(msg=str(error))
        return
    module.exit_json(
        changed=bool(state.missing),
        installed=list(installed),
        **asdict(state),
    )


if __name__ == "__main__":
    main()
