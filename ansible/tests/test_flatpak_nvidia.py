import importlib.util
import sys
from pathlib import Path
from types import ModuleType
from typing import Any, cast


def _flatpak_module() -> ModuleType:
    path = (
        Path(__file__).parents[1] / "roles/desktop/library/dotfiles_flatpak_nvidia.py"
    )
    spec = importlib.util.spec_from_file_location("dotfiles_flatpak_nvidia", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


flatpak = cast("Any", _flatpak_module())


def test_runtime_reference_discovery_is_exact_and_deduplicated() -> None:
    assert flatpak.gl_runtime_references(
        "default\nnvidia-570-1\nnvidia-570-1\nhost\n",
    ) == ("org.freedesktop.Platform.GL.nvidia-570-1//1.4",)
    assert flatpak.vaapi_runtime_references(
        "org.freedesktop.Platform.VAAPI.nvidia 24.08\n"
        "org.example.Other 1\n"
        "org.freedesktop.Platform.VAAPI.nvidia\t25.08\n",
    ) == (
        "org.freedesktop.Platform.VAAPI.nvidia//24.08",
        "org.freedesktop.Platform.VAAPI.nvidia//25.08",
    )


def test_scope_inspection_queries_exact_architecture_and_branches() -> None:
    responses = {
        ("flatpak", "--default-arch"): flatpak.CommandResult(0, "x86_64\n"),
        ("flatpak", "--gl-drivers"): flatpak.CommandResult(0, "nvidia-570\n"),
        (
            "flatpak",
            "remotes",
            "--user",
            "--columns=name",
        ): flatpak.CommandResult(0, "flathub\n"),
        (
            "flatpak",
            "remote-ls",
            "--user",
            "flathub",
            "--runtime",
            "--columns=application,branch",
        ): flatpak.CommandResult(
            0,
            "org.freedesktop.Platform.VAAPI.nvidia 24.08\n",
        ),
        (
            "flatpak",
            "info",
            "--user",
            "--arch=x86_64",
            "org.freedesktop.Platform.GL.nvidia-570",
            "1.4",
        ): flatpak.CommandResult(0, ""),
        (
            "flatpak",
            "info",
            "--user",
            "--arch=x86_64",
            "org.freedesktop.Platform.VAAPI.nvidia",
            "24.08",
        ): flatpak.CommandResult(1, ""),
    }
    state = flatpak.inspect_scope(
        flatpak.ScopeConfig("flatpak", "user"),
        lambda argv: responses[tuple(argv)],
    )

    assert state.required == (
        "org.freedesktop.Platform.GL.nvidia-570//1.4",
        "org.freedesktop.Platform.VAAPI.nvidia//24.08",
    )
    assert state.missing == ("org.freedesktop.Platform.VAAPI.nvidia//24.08",)


def test_check_mode_does_not_install_missing_runtimes() -> None:
    state = flatpak.ScopeState(
        architecture="aarch64",
        remote_available=True,
        required=("org.freedesktop.Platform.GL.nvidia-1//1.4",),
        missing=("org.freedesktop.Platform.GL.nvidia-1//1.4",),
    )
    calls: list[tuple[str, ...]] = []
    installed = flatpak.install_missing(
        flatpak.ScopeConfig("flatpak", "system"),
        state,
        lambda argv: calls.append(tuple(argv)),
        check_mode=True,
    )

    assert installed == ()
    assert calls == []


def test_missing_runtimes_are_installed_as_exact_references() -> None:
    references = (
        "org.freedesktop.Platform.GL.nvidia-1//1.4",
        "org.freedesktop.Platform.VAAPI.nvidia//24.08",
    )
    state = flatpak.ScopeState(
        architecture="x86_64",
        remote_available=True,
        required=references,
        missing=references,
    )
    calls: list[tuple[str, ...]] = []
    installed = flatpak.install_missing(
        flatpak.ScopeConfig("flatpak", "user"),
        state,
        lambda argv: calls.append(tuple(argv)) or flatpak.CommandResult(0, ""),
        check_mode=False,
    )

    assert installed == references
    assert calls == [
        ("flatpak", "install", "--user", "--noninteractive", "flathub", reference)
        for reference in references
    ]
