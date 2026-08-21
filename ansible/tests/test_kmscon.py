import importlib.util
import json
import subprocess
import sys
from pathlib import Path
from types import ModuleType
from typing import Protocol, cast

import pytest

REPOSITORY = Path(__file__).parents[2]
REFRESH_SCRIPT = REPOSITORY / "ansible/roles/system/files/kmscon/kmscon-refresh.py"


class RefreshModule(Protocol):
    subprocess: ModuleType

    def load_pending(self, _state_path: Path, _digest: str) -> set[str]: ...

    def refresh(self, config: Path, state: Path) -> int: ...

    def session_tty(self, _session_id: str) -> str | None: ...


def load_script(name: str, path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location(name, path)
    assert spec is not None
    assert spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def refresh_module() -> RefreshModule:
    return cast("RefreshModule", load_script("kmscon_refresh_test", REFRESH_SCRIPT))


def test_refresh_tracks_occupied_ttys_until_they_can_restart(
    refresh_module: RefreshModule,
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    config = tmp_path / "kmscon.conf"
    state = tmp_path / "state.json"
    config.write_text("palette=custom\n", encoding="utf-8")
    occupied = {"tty1"}
    calls: list[tuple[str, ...]] = []

    monkeypatch.setattr(refresh_module, "logged_in_ttys", lambda: occupied)

    def record(
        argv: tuple[str, ...], *, check: bool
    ) -> subprocess.CompletedProcess[str]:
        del check
        calls.append(argv)
        return subprocess.CompletedProcess(argv, 0)

    monkeypatch.setattr(refresh_module.subprocess, "run", record)

    assert refresh_module.refresh(config, state) == 0
    assert [call[-1] for call in calls] == [
        f"kmsconvt@tty{number}.service" for number in range(2, 7)
    ]
    assert json.loads(state.read_text(encoding="utf-8"))["pending_ttys"] == ["tty1"]

    calls.clear()
    assert refresh_module.refresh(config, state) == 0
    assert calls == []

    occupied.clear()
    assert refresh_module.refresh(config, state) == 0
    assert [call[-1] for call in calls] == ["kmsconvt@tty1.service"]
    assert json.loads(state.read_text(encoding="utf-8"))["pending_ttys"] == []

    calls.clear()
    assert refresh_module.refresh(config, state) == 0
    assert calls == []


def test_refresh_recovers_from_corrupt_state(
    refresh_module: RefreshModule,
    tmp_path: Path,
) -> None:
    state = tmp_path / "state.json"
    state.write_text("not-json", encoding="utf-8")

    assert refresh_module.load_pending(state, "expected") == {
        f"tty{number}" for number in range(1, 7)
    }


@pytest.mark.parametrize(
    ("properties", "expected"),
    [
        ("TTY=tty3\nVTNr=3\n", "tty3"),
        ("TTY=pts/4\nVTNr=4\n", "tty4"),
        ("TTY=pts/9\nVTNr=0\n", None),
    ],
)
def test_session_tty_uses_loginctl_properties(
    refresh_module: RefreshModule,
    monkeypatch: pytest.MonkeyPatch,
    properties: str,
    expected: str | None,
) -> None:
    monkeypatch.setattr(refresh_module, "command_output", lambda _argv: properties)

    assert refresh_module.session_tty("session") == expected
