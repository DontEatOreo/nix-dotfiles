#!/usr/bin/python
"""Manage one GNOME Shell extension from EGO or local build artifacts."""

from __future__ import annotations

import ast
import filecmp
import json
import re
import shutil
import tempfile
from collections.abc import Callable, Sequence
from dataclasses import asdict, dataclass
from itertools import starmap
from pathlib import Path
from urllib.parse import urlencode, urljoin, urlsplit

try:
    from ansible.module_utils.basic import (  # ty: ignore[unresolved-import]
        AnsibleModule,
    )
    from ansible.module_utils.urls import (  # ty: ignore[unresolved-import]
        fetch_file,
        fetch_url,
    )
except ModuleNotFoundError:
    AnsibleModule = None  # type: ignore[assignment,misc]
    fetch_file = fetch_url = None  # type: ignore[assignment]

DOCUMENTATION = r"""
---
module: dotfiles_gnome_extension
short_description: Manage one GNOME Shell extension
description:
  - Installs a compatible extension from extensions.gnome.org or local build artifacts.
  - Reconciles the installed version and enables the extension persistently.
  - Uses GNOME's GSettings fallback when a live Shell has not loaded a new extension.
author: 4evy
options:
  uuid:
    description: GNOME Shell extension UUID.
    required: true
    type: str
  extension_root:
    description: Directory containing per-UUID user extension directories.
    required: true
    type: path
  shell_version:
    description: GNOME Shell major version used to select a compatible EGO release.
    type: str
  origin:
    description: extensions.gnome.org-compatible origin for remote discovery.
    type: str
  cache_dir:
    description: Directory used to cache remote extension archives.
    type: path
  metadata_path:
    description: Local metadata.json build artifact.
    type: path
  extension_path:
    description: Local extension.js build artifact.
    type: path
  schema_paths:
    description: Local GSettings schema XML build artifacts.
    type: list
    elements: path
    default: []
  enable:
    description: Enable the extension in the active GNOME session when possible.
    type: bool
    default: true
"""

EXAMPLES = r"""
- name: Install a compatible extension from extensions.gnome.org
  dotfiles_gnome_extension:
    uuid: focused-window-dbus@flexagoon.com
    extension_root: "{{ dotfiles_data_home }}/gnome-shell/extensions"
    shell_version: "{{ gnome_shell_major }}"
    origin: https://extensions.gnome.org
    cache_dir: "{{ dotfiles_cache_home }}/dotfiles/gnome-extensions"

- name: Install a locally built extension
  dotfiles_gnome_extension:
    uuid: hyper-window-tiling@4evy.local
    extension_root: "{{ dotfiles_data_home }}/gnome-shell/extensions"
    metadata_path: /source/gnome/metadata.json
    extension_path: /source/dist/gnome/extension.js
    schema_paths:
      - /source/gnome/schemas/org.example.gschema.xml
"""

RETURN = r"""
available:
  description: Whether a compatible remote release or valid local source was available.
  returned: always
  type: bool
uuid:
  description: Managed extension UUID.
  returned: always
  type: str
version:
  description: Selected remote release version, when applicable.
  returned: always
  type: str
enabled:
  description: Whether GNOME accepted the extension enablement request.
  returned: always
  type: bool
"""

UUID_PATTERN = re.compile(r"^[A-Za-z0-9._+@-]+$")
VERSION_PATTERN = re.compile(r"^[A-Za-z0-9._+-]+$")


@dataclass(frozen=True)
class CommandResult:
    returncode: int
    stdout: str
    stderr: str = ""


@dataclass(frozen=True)
class ExtensionConfig:
    uuid: str
    extension_root: Path
    command: str = "gnome-extensions"
    environment_command: str = "env"
    settings_command: str = "gsettings"
    enable: bool = True
    shell_version: str | None = None
    origin: str | None = None
    cache_dir: Path | None = None
    metadata_path: Path | None = None
    extension_path: Path | None = None
    schema_paths: tuple[Path, ...] = ()


@dataclass(frozen=True)
class ExtensionState:
    available: bool
    uuid: str
    version: str | None
    enabled: bool


@dataclass(frozen=True)
class ReconcileResult:
    changed: bool
    state: ExtensionState


Runner = Callable[[Sequence[str]], CommandResult]
Fetcher = Callable[[str], bytes]
Downloader = Callable[[str, Path], None]


def metadata_url(config: ExtensionConfig) -> str:
    """Build the extensions.gnome.org compatibility query URL."""
    if config.origin is None or config.shell_version is None:
        raise ValueError("remote source is incomplete")
    query = urlencode({"uuid": config.uuid, "shell_version": config.shell_version})
    return f"{config.origin.rstrip('/')}/extension-info/?{query}"


def remote_release(payload: bytes) -> tuple[str, str] | None:
    """Parse a compatible EGO release as a version and download URL."""
    document: object = json.loads(payload)
    if not isinstance(document, dict):
        raise TypeError("GNOME extension metadata was not an object")
    version = document.get("version")
    download_url = document.get("download_url")
    if version is None or not isinstance(download_url, str) or not download_url:
        return None
    version_text = str(version)
    if not VERSION_PATTERN.fullmatch(version_text):
        msg = f"invalid GNOME extension version: {version_text}"
        raise ValueError(msg)
    return version_text, download_url


def installed_version(config: ExtensionConfig) -> str | None:
    """Read the installed metadata without requiring a live Shell D-Bus API."""
    extension_dir = config.extension_root / config.uuid
    metadata_path = extension_dir / "metadata.json"
    if not (extension_dir / "extension.js").is_file():
        return None
    try:
        metadata: object = json.loads(metadata_path.read_bytes())
    except OSError, json.JSONDecodeError:
        return None
    if not isinstance(metadata, dict) or metadata.get("uuid") != config.uuid:
        return None
    version = metadata.get("version")
    return str(version) if version is not None else None


def files_differ(source: Path, destination: Path) -> bool:
    """Compare source and destination bytes with the standard library."""
    return not destination.is_file() or not filecmp.cmp(
        source,
        destination,
        shallow=False,
    )


def local_sources(config: ExtensionConfig) -> tuple[tuple[Path, Path], ...]:
    """Map local GNOME build artifacts to their extension destinations."""
    if config.metadata_path is None or config.extension_path is None:
        raise ValueError("local source is incomplete")
    extension_dir = config.extension_root / config.uuid
    pairs = [
        (config.metadata_path, extension_dir / "metadata.json"),
        (config.extension_path, extension_dir / "extension.js"),
    ]
    pairs.extend(
        (schema, extension_dir / "schemas" / schema.name)
        for schema in config.schema_paths
    )
    for source, _destination in pairs:
        if not source.is_file():
            msg = f"GNOME extension source does not exist: {source}"
            raise ValueError(msg)
    metadata = json.loads(config.metadata_path.read_text())
    if not isinstance(metadata, dict) or metadata.get("uuid") != config.uuid:
        msg = f"metadata UUID does not match {config.uuid}"
        raise ValueError(msg)
    return tuple(pairs)


def reconcile_local(
    config: ExtensionConfig,
    run: Runner,
    *,
    check_mode: bool,
) -> bool:
    """Package and install changed local artifacts with GNOME's own CLI."""
    pairs = local_sources(config)
    compiled_schema = (
        config.extension_root / config.uuid / "schemas" / "gschemas.compiled"
    )
    changed = any(starmap(files_differ, pairs)) or (
        bool(config.schema_paths) and not compiled_schema.is_file()
    )
    if check_mode:
        return changed
    if not changed:
        return False
    with tempfile.TemporaryDirectory(prefix=f"{config.uuid}-gnome-") as temporary:
        workspace = Path(temporary)
        source_dir = workspace / "source"
        output_dir = workspace / "output"
        source_dir.mkdir()
        output_dir.mkdir()
        if config.metadata_path is None or config.extension_path is None:
            raise ValueError("local source is incomplete")
        shutil.copy2(config.metadata_path, source_dir / "metadata.json")
        shutil.copy2(config.extension_path, source_dir / "extension.js")
        if config.schema_paths:
            schemas = source_dir / "schemas"
            schemas.mkdir()
            for schema in config.schema_paths:
                shutil.copy2(schema, schemas / schema.name)
        packed = run(
            (
                config.command,
                "pack",
                "--force",
                "--out-dir",
                str(output_dir),
                str(source_dir),
            ),
        )
        if packed.returncode != 0:
            message = packed.stderr.strip() or packed.stdout.strip()
            msg = f"failed to package GNOME extension {config.uuid}: {message}"
            raise RuntimeError(msg)
        archive = output_dir / f"{config.uuid}.shell-extension.zip"
        installed = run(
            (
                config.command,
                "install",
                "--force",
                "--print-uuid",
                str(archive),
            ),
        )
        if installed.returncode != 0 or installed.stdout.strip() != config.uuid:
            message = installed.stderr.strip() or installed.stdout.strip()
            msg = f"failed to install GNOME extension {config.uuid}: {message}"
            raise RuntimeError(msg)
    return True


def cache_archive(
    config: ExtensionConfig,
    version: str,
    download_url: str,
    download: Downloader,
) -> Path:
    """Cache a remote extension archive through Ansible's atomic downloader."""
    if config.cache_dir is None or config.origin is None:
        raise ValueError("remote cache is incomplete")
    config.cache_dir.mkdir(parents=True, exist_ok=True, mode=0o755)
    archive = config.cache_dir / f"{config.uuid}-{version}.shell-extension.zip"
    if not archive.is_file():
        download(
            urljoin(f"{config.origin.rstrip('/')}/", download_url),
            archive,
        )
    return archive


def enable_extension(
    config: ExtensionConfig, run: Runner, *, check_mode: bool
) -> tuple[bool, bool]:
    """Enable through Shell or GNOME's headless GSettings fallback."""
    listed = run((config.command, "list", "--enabled"))
    state_known = listed.returncode == 0
    active = state_known and config.uuid in listed.stdout.splitlines()
    if active or not config.enable:
        return False, active
    enabled = string_array_setting(config, run, "enabled-extensions")
    disabled = string_array_setting(config, run, "disabled-extensions")
    persistent = (
        config.uuid in enabled and config.uuid not in disabled
        if enabled is not None and disabled is not None
        else None
    )
    if persistent:
        return False, True
    if check_mode:
        return persistent is False, False
    result = run((config.command, "enable", config.uuid))
    if result.returncode == 0:
        return state_known or persistent is False, True
    fallback = run(
        (
            config.environment_command,
            "-u",
            "DBUS_SESSION_BUS_ADDRESS",
            config.command,
            "enable",
            config.uuid,
        ),
    )
    succeeded = fallback.returncode == 0
    return persistent is False and succeeded, succeeded


def string_array_setting(
    config: ExtensionConfig,
    run: Runner,
    key: str,
) -> frozenset[str] | None:
    """Read a GNOME string-array setting with Python's safe literal parser."""
    result = run((config.settings_command, "get", "org.gnome.shell", key))
    if result.returncode != 0:
        return None
    value = result.stdout.strip().removeprefix("@as ")
    try:
        parsed: object = ast.literal_eval(value)
    except SyntaxError, ValueError:
        return None
    if not isinstance(parsed, list) or not all(
        isinstance(item, str) for item in parsed
    ):
        return None
    return frozenset(item for item in parsed if isinstance(item, str))


def reconcile_remote(
    config: ExtensionConfig,
    run: Runner,
    fetch: Fetcher,
    download: Downloader | None,
    *,
    check_mode: bool,
) -> tuple[bool, str] | None:
    """Reconcile an extensions.gnome.org-compatible release."""
    try:
        release = remote_release(fetch(metadata_url(config)))
    except FileNotFoundError:
        return None
    if release is None:
        return None
    version, download_url = release
    install_needed = installed_version(config) != version
    if install_needed and not check_mode:
        if download is None:
            raise RuntimeError("remote installation requires a downloader")
        archive = cache_archive(config, version, download_url, download)
        result = run(
            (
                config.command,
                "install",
                "--force",
                "--print-uuid",
                str(archive),
            ),
        )
        if result.returncode != 0 or result.stdout.strip() != config.uuid:
            message = result.stderr.strip() or result.stdout.strip()
            msg = f"failed to install GNOME extension {config.uuid}: {message}"
            raise RuntimeError(msg)
    return install_needed, version


def reconcile_extension(
    config: ExtensionConfig,
    run: Runner,
    fetch: Fetcher,
    *,
    check_mode: bool,
    download: Downloader | None = None,
) -> ReconcileResult:
    """Reconcile one extension and its active-session state."""
    if not UUID_PATTERN.fullmatch(config.uuid):
        msg = f"invalid GNOME extension UUID: {config.uuid}"
        raise ValueError(msg)
    version: str | None = None
    if config.shell_version is not None:
        remote_result = reconcile_remote(
            config,
            run,
            fetch,
            download,
            check_mode=check_mode,
        )
        if remote_result is None:
            return ReconcileResult(
                changed=False,
                state=ExtensionState(False, config.uuid, None, False),
            )
        source_changed, version = remote_result
    else:
        source_changed = reconcile_local(config, run, check_mode=check_mode)
    enable_changed, enabled = enable_extension(
        config,
        run,
        check_mode=check_mode,
    )
    return ReconcileResult(
        changed=source_changed or enable_changed,
        state=ExtensionState(True, config.uuid, version, enabled),
    )


def require_https(url: str) -> str:
    """Reject transport URLs that would expose extension code in plaintext."""
    if urlsplit(url).scheme != "https":
        raise ValueError(f"GNOME extension URL must use HTTPS: {url}")
    return url


def optional_path(value: str | None) -> Path | None:
    """Convert an optional Ansible path parameter."""
    return Path(value) if value is not None else None


def main() -> None:
    """Ansible module entry point."""
    if AnsibleModule is None or fetch_file is None or fetch_url is None:
        raise RuntimeError("Ansible is required to execute this module")
    file_downloader = fetch_file
    url_fetcher = fetch_url
    module = AnsibleModule(
        argument_spec={
            "uuid": {"type": "str", "required": True},
            "extension_root": {"type": "path", "required": True},
            "shell_version": {"type": "str"},
            "origin": {"type": "str"},
            "cache_dir": {"type": "path"},
            "metadata_path": {"type": "path"},
            "extension_path": {"type": "path"},
            "schema_paths": {"type": "list", "elements": "path", "default": []},
            "enable": {"type": "bool", "default": True},
        },
        supports_check_mode=True,
        required_together=(
            ("shell_version", "origin", "cache_dir"),
            ("metadata_path", "extension_path"),
        ),
        required_one_of=(("shell_version", "metadata_path"),),
        mutually_exclusive=(("shell_version", "metadata_path"),),
    )
    schemas = tuple(Path(path) for path in module.params["schema_paths"])
    config = ExtensionConfig(
        uuid=module.params["uuid"],
        extension_root=Path(module.params["extension_root"]),
        command=module.get_bin_path("gnome-extensions", required=True),
        environment_command=module.get_bin_path("env", required=True),
        settings_command=module.get_bin_path("gsettings", required=True),
        enable=module.params["enable"],
        shell_version=module.params["shell_version"],
        origin=module.params["origin"],
        cache_dir=optional_path(module.params["cache_dir"]),
        metadata_path=optional_path(module.params["metadata_path"]),
        extension_path=optional_path(module.params["extension_path"]),
        schema_paths=schemas,
    )

    def run(argv: Sequence[str]) -> CommandResult:
        returncode, stdout, stderr = module.run_command(
            list(argv),
            environ_update={
                "LC_ALL": "C",
                "XDG_DATA_HOME": str(config.extension_root.parent.parent),
            },
        )
        return CommandResult(returncode, stdout, stderr)

    def fetch(url: str) -> bytes:
        response, info = url_fetcher(module, require_https(url), timeout=30)
        status = int(info.get("status", -1))
        if status == 404:
            raise FileNotFoundError(url)
        if response is None or status >= 400 or status < 0:
            raise RuntimeError(f"failed to fetch {url}: {info.get('msg', status)}")
        with response:
            return response.read()

    def download(url: str, destination: Path) -> None:
        temporary = file_downloader(module, require_https(url), timeout=30)
        module.atomic_move(temporary, str(destination))

    try:
        result = reconcile_extension(
            config,
            run,
            fetch,
            check_mode=module.check_mode,
            download=download,
        )
    except (
        OSError,
        RuntimeError,
        TypeError,
        ValueError,
        json.JSONDecodeError,
    ) as error:
        module.fail_json(msg=str(error))
        return
    module.exit_json(changed=result.changed, **asdict(result.state))


if __name__ == "__main__":
    main()
