import json
import os
from collections.abc import Sequence
from pathlib import Path
from subprocess import CompletedProcess
from typing import TYPE_CHECKING

from workstation.apps import discord

if TYPE_CHECKING:
    import pytest


def _discord_app(tmp_path: Path) -> tuple[Path, Path]:
    app = tmp_path / "Discord.app"
    resources = app / "Contents/Resources"
    resources.mkdir(parents=True)
    (resources / "app.asar").write_bytes(b"clean Discord ASAR")
    return app, resources


def test_gpu_configuration_preserves_unrelated_settings(tmp_path: Path) -> None:
    settings = tmp_path / "settings.json"
    settings.write_text(
        json.dumps({
            "unrelated": "preserved",
            "chromiumSwitches": {"existing_switch": "preserved"},
        })
    )

    discord._configure_gpu(tmp_path)

    configured = json.loads(settings.read_text())
    assert configured["unrelated"] == "preserved"
    assert configured["enableHardwareAcceleration"] is True
    assert configured["chromiumSwitches"] == {
        "existing_switch": "preserved",
        "force_high_performance_gpu": True,
    }


def test_macos_repair_falls_back_to_install_and_locks_asars(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    app, resources = _discord_app(tmp_path)
    equilotl = tmp_path / "EquilotlCli-darwin-arm64"
    equilotl.write_text("#!/bin/sh\n")
    equilotl.chmod(0o755)
    commands: list[tuple[str, ...]] = []

    def fake_run(
        argv: Sequence[str | os.PathLike[str]], **_kwargs: object
    ) -> CompletedProcess[str]:
        command = tuple(map(str, argv))
        commands.append(command)
        if "--repair" in command:
            return CompletedProcess(command, 1, "", "")
        if "--install" in command:
            (resources / "app.asar").write_bytes(
                b'require("Equicord/equicord.asar")\n{"name": "discord"}'
            )
        return CompletedProcess(command, 0, "", "")

    monkeypatch.setenv("DISCORD_EQUICORD_APP", str(app))
    monkeypatch.setenv("DISCORD_EQUICORD_EQUILOTL", str(equilotl))
    monkeypatch.setattr(discord, "run", fake_run)

    discord._repair_macos(tmp_path)

    assert [command[1] for command in commands] == [
        "nouchg",
        "--repair",
        "--install",
        "uchg",
    ]


def test_macos_repair_refreshes_and_relocks_when_equicord_is_present(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    app, resources = _discord_app(tmp_path)
    equilotl = tmp_path / "EquilotlCli-darwin-arm64"
    equilotl.write_text("#!/bin/sh\n")
    equilotl.chmod(0o755)
    (resources / "app.asar").write_bytes(
        b'require("Equicord/equicord.asar")\n{"name": "discord"}'
    )
    commands: list[tuple[str, ...]] = []

    def fake_run(
        argv: Sequence[str | os.PathLike[str]], **_kwargs: object
    ) -> CompletedProcess[str]:
        command = tuple(map(str, argv))
        commands.append(command)
        return CompletedProcess(command, 0, "", "")

    monkeypatch.setenv("DISCORD_EQUICORD_APP", str(app))
    monkeypatch.setenv("DISCORD_EQUICORD_EQUILOTL", str(equilotl))
    monkeypatch.setattr(discord, "run", fake_run)

    discord._repair_macos(tmp_path)

    assert commands == [
        ("chflags", "nouchg", str(resources / "app.asar")),
        (
            str(equilotl),
            "--repair",
            "--branch",
            "stable",
        ),
        ("chflags", "uchg", str(resources / "app.asar")),
    ]


def test_macos_repair_relocks_asars_after_failed_install(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    app, resources = _discord_app(tmp_path)
    equilotl = tmp_path / "EquilotlCli-darwin-arm64"
    equilotl.write_text("#!/bin/sh\n")
    equilotl.chmod(0o755)
    commands: list[tuple[str, ...]] = []

    def fake_run(
        argv: Sequence[str | os.PathLike[str]], **_kwargs: object
    ) -> CompletedProcess[str]:
        command = tuple(map(str, argv))
        commands.append(command)
        return CompletedProcess(command, 1, "", "")

    monkeypatch.setenv("DISCORD_EQUICORD_APP", str(app))
    monkeypatch.setenv("DISCORD_EQUICORD_EQUILOTL", str(equilotl))
    monkeypatch.setattr(discord, "run", fake_run)

    with pytest.raises(discord.DotfilesError):
        discord._repair_macos(tmp_path)

    assert [command[1] for command in commands] == [
        "nouchg",
        "--repair",
        "--install",
        "uchg",
    ]


def test_linux_patch_repairs_loader_from_previous_home(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    location = tmp_path / "discord/app-1.0.0"
    resources = location / "resources"
    resources.mkdir(parents=True)
    (resources / "app.asar").write_bytes(
        b'require("/var/home/old/.config/Equicord/equicord.asar"){"name": "discord"}'
    )
    (resources / "build_info.json").write_text("{}")
    equilotl = tmp_path / "EquilotlCli-linux"
    equilotl.write_text("#!/bin/sh\n")
    equilotl.chmod(0o755)
    commands: list[tuple[str, ...]] = []

    def fake_run(
        argv: Sequence[str | os.PathLike[str]], **_kwargs: object
    ) -> CompletedProcess[str]:
        command = tuple(map(str, argv))
        commands.append(command)
        return CompletedProcess(command, 0, "", "")

    monkeypatch.setattr(discord, "user_config_home", lambda: tmp_path / "config")
    monkeypatch.setattr(discord, "run", fake_run)

    discord._patch_location(location, equilotl)

    assert commands == [(str(equilotl), "--repair", "--location", str(location))]


def test_linux_equilotl_uses_homebrew_path(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    equilotl = tmp_path / "homebrew/bin/equilotl"
    equilotl.parent.mkdir(parents=True)
    equilotl.write_text("#!/bin/sh\n")
    equilotl.chmod(0o755)
    legacy = tmp_path / "user-bin/EquilotlCli-linux"
    legacy.parent.mkdir(parents=True)
    legacy.write_text("#!/bin/sh\n")
    legacy.chmod(0o755)

    monkeypatch.delenv("DISCORD_EQUICORD_EQUILOTL", raising=False)
    monkeypatch.setattr(discord, "user_bin_home", lambda: tmp_path / "user-bin")
    monkeypatch.setattr(
        discord.shutil,
        "which",
        lambda command: str(equilotl) if command == "equilotl" else None,
    )

    assert discord._linux_equilotl(tmp_path / "package-bin") == equilotl
