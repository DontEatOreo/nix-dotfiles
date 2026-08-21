import importlib.util
import json
import sys
from pathlib import Path
from types import ModuleType
from typing import Any, cast


def _gnome_module() -> ModuleType:
    path = Path(__file__).parents[1] / "library/dotfiles_gnome_extension.py"
    spec = importlib.util.spec_from_file_location("dotfiles_gnome_extension", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


gnome = cast("Any", _gnome_module())


def _reconcile(
    config: Any,  # ruff: ignore[any-type]
    run: Any,  # ruff: ignore[any-type]
    payload: bytes = b"",
    *,
    check_mode: bool = False,
) -> Any:  # ruff: ignore[any-type]
    return gnome.reconcile_extension(
        config,
        run,
        lambda _url: payload,
        check_mode=check_mode,
    )


def _remote_config(tmp_path: Path) -> Any:  # ruff: ignore[any-type]
    return gnome.ExtensionConfig(
        uuid="example@test",
        extension_root=tmp_path / "extensions",
        shell_version="50",
        origin="https://extensions.gnome.org",
        cache_dir=tmp_path / "cache",
    )


class _LocalExtensionRunner:
    def __init__(
        self,
        metadata: Path,
        extension: Path,
        schema: Path,
        destination: Path,
    ) -> None:
        self.metadata = metadata
        self.extension = extension
        self.schema = schema
        self.destination = destination
        self.calls: list[tuple[str, ...]] = []
        self.session_enabled = False
        self.persistent = False

    def __call__(self, argv: list[str] | tuple[str, ...]) -> object:
        call = tuple(argv)
        self.calls.append(call)
        if call == ("gnome-extensions", "list", "--enabled"):
            output = "example@test\n" if self.session_enabled else ""
            return gnome.CommandResult(0, output)
        if call[-1] == "enabled-extensions":
            value = "['example@test']\n" if self.persistent else "@as []\n"
            return gnome.CommandResult(0, value)
        if call[-1] == "disabled-extensions":
            return gnome.CommandResult(0, "@as []\n")
        if call[1] == "pack":
            package_source = Path(call[5])
            assert (
                package_source / "metadata.json"
            ).read_text() == self.metadata.read_text()
            assert (
                package_source / "extension.js"
            ).read_text() == self.extension.read_text()
            assert (
                package_source / "schemas" / self.schema.name
            ).read_text() == self.schema.read_text()
            (Path(call[4]) / "example@test.shell-extension.zip").write_bytes(b"zip")
        if call[1] == "install":
            assert Path(call[4]).read_bytes() == b"zip"
            schemas = self.destination / "schemas"
            schemas.mkdir(parents=True, exist_ok=True)
            (self.destination / "metadata.json").write_bytes(self.metadata.read_bytes())
            (self.destination / "extension.js").write_bytes(self.extension.read_bytes())
            (schemas / self.schema.name).write_bytes(self.schema.read_bytes())
            (schemas / "gschemas.compiled").write_bytes(b"compiled")
            return gnome.CommandResult(0, "example@test\n")
        if call == ("gnome-extensions", "enable", "example@test"):
            self.persistent = True
            self.session_enabled = True
        return gnome.CommandResult(0, "")


def test_remote_check_mode_reports_install_and_enable_without_mutation(
    tmp_path: Path,
) -> None:
    calls: list[tuple[str, ...]] = []

    def run(argv: list[str] | tuple[str, ...]) -> object:
        call = tuple(argv)
        calls.append(call)
        responses: dict[tuple[str, ...], object] = {
            ("gnome-extensions", "list", "--enabled"): gnome.CommandResult(0, ""),
            (
                "gsettings",
                "get",
                "org.gnome.shell",
                "enabled-extensions",
            ): gnome.CommandResult(0, "@as []\n"),
            (
                "gsettings",
                "get",
                "org.gnome.shell",
                "disabled-extensions",
            ): gnome.CommandResult(0, "@as []\n"),
        }
        return responses[call]

    result = _reconcile(
        _remote_config(tmp_path),
        run,
        json.dumps(
            {"version": 5, "download_url": "/download/1.shell-extension.zip"},
        ).encode(),
        check_mode=True,
    )

    assert result.changed
    assert result.state.available
    assert result.state.version == "5"
    assert not result.state.enabled
    assert all("install" not in call for call in calls)
    assert all("enable" not in call for call in calls)
    assert not (tmp_path / "cache").exists()


def test_remote_current_version_uses_gsettings_fallback_idempotently(
    tmp_path: Path,
) -> None:
    installed = tmp_path / "extensions/example@test"
    installed.mkdir(parents=True)
    (installed / "metadata.json").write_text(
        '{"uuid": "example@test", "version": 5}\n',
    )
    (installed / "extension.js").write_text("export default class Example {}\n")
    calls: list[tuple[str, ...]] = []
    persistent = False

    def run(argv: list[str] | tuple[str, ...]) -> object:
        nonlocal persistent
        call = tuple(argv)
        calls.append(call)
        if call == ("gnome-extensions", "list", "--enabled"):
            return gnome.CommandResult(0, "")
        if call[-1] == "enabled-extensions":
            return gnome.CommandResult(0, "['example@test']\n")
        if call[-1] == "disabled-extensions":
            value = "@as []\n" if persistent else "['example@test']\n"
            return gnome.CommandResult(0, value)
        if call == ("gnome-extensions", "enable", "example@test"):
            return gnome.CommandResult(2, "")
        if call[0] == "env":
            persistent = True
            return gnome.CommandResult(0, "")
        raise AssertionError(call)

    config = _remote_config(tmp_path)
    first = _reconcile(
        config,
        run,
        b'{"version": 5, "download_url": "/download.zip"}',
    )

    assert first.changed
    assert first.state.enabled
    assert calls[-1] == (
        "env",
        "-u",
        "DBUS_SESSION_BUS_ADDRESS",
        "gnome-extensions",
        "enable",
        "example@test",
    )

    calls.clear()
    second = _reconcile(
        config,
        run,
        b'{"version": 5, "download_url": "/download.zip"}',
    )

    assert not second.changed
    assert second.state.enabled
    assert calls == [
        ("gnome-extensions", "list", "--enabled"),
        ("gsettings", "get", "org.gnome.shell", "enabled-extensions"),
        ("gsettings", "get", "org.gnome.shell", "disabled-extensions"),
    ]


def test_missing_compatible_remote_release_is_available_false(tmp_path: Path) -> None:
    result = _reconcile(
        _remote_config(tmp_path),
        lambda _argv: gnome.CommandResult(1, ""),
        b'{"error": "No compatible version"}',
    )

    assert not result.changed
    assert not result.state.available


def test_remote_archive_uses_downloader_once(tmp_path: Path) -> None:
    calls: list[tuple[str, Path]] = []

    def download(url: str, destination: Path) -> None:
        calls.append((url, destination))
        destination.write_bytes(b"extension")

    config = _remote_config(tmp_path)
    first = gnome.cache_archive(config, "5", "/download.zip", download)
    second = gnome.cache_archive(config, "5", "/download.zip", download)

    assert first == second
    assert first.read_bytes() == b"extension"
    assert calls == [("https://extensions.gnome.org/download.zip", first)]


def test_local_source_uses_gnome_pack_install_and_is_idempotent(
    tmp_path: Path,
) -> None:
    source = tmp_path / "source"
    source.mkdir()
    metadata = source / "metadata.json"
    extension = source / "extension.js"
    schema = source / "org.example.gschema.xml"
    metadata.write_text('{"uuid": "example@test"}\n')
    extension.write_text("export default class Example {}\n")
    schema.write_text("<schemalist/>\n")
    destination = tmp_path / "extensions/example@test"
    runner = _LocalExtensionRunner(metadata, extension, schema, destination)

    config = gnome.ExtensionConfig(
        uuid="example@test",
        extension_root=tmp_path / "extensions",
        metadata_path=metadata,
        extension_path=extension,
        schema_paths=(schema,),
    )
    check = _reconcile(config, runner, check_mode=True)
    assert check.changed
    assert not destination.exists()
    assert runner.calls == [
        ("gnome-extensions", "list", "--enabled"),
        ("gsettings", "get", "org.gnome.shell", "enabled-extensions"),
        ("gsettings", "get", "org.gnome.shell", "disabled-extensions"),
    ]

    runner.calls.clear()
    first = _reconcile(config, runner)

    assert first.changed
    assert (destination / "metadata.json").read_text() == metadata.read_text()
    assert (destination / "extension.js").read_text() == extension.read_text()
    assert (destination / "schemas" / schema.name).read_text() == schema.read_text()
    assert any(call[1] == "pack" for call in runner.calls)
    assert any(call[1] == "install" for call in runner.calls)
    assert ("gnome-extensions", "enable", "example@test") in runner.calls

    runner.calls.clear()
    second = _reconcile(config, runner)
    assert not second.changed
    assert second.state.enabled
    assert runner.calls == [("gnome-extensions", "list", "--enabled")]

    (destination / "schemas" / "gschemas.compiled").unlink()
    runner.calls.clear()
    repair = _reconcile(config, runner)
    assert repair.changed
    assert any(call[1] == "pack" for call in runner.calls)
