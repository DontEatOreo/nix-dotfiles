from __future__ import annotations

import subprocess
from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    import pytest

SCRIPT = (
    Path(__file__).parents[1] / "roles" / "keyboard" / "files" / "toshy" / "setup.py"
)
SPEC = spec_from_file_location("toshy_setup", SCRIPT)
assert SPEC is not None
assert SPEC.loader is not None
SETUP = module_from_spec(SPEC)
SPEC.loader.exec_module(SETUP)


def test_answers_safety_prompts_and_dynamic_secret() -> None:
    assert SETUP.answer_for("The secret code 'rose-42'") == "rose-42"
    assert SETUP.answer_for('Barebones: Enter "YES" to proceed or "n"') == "YES"
    assert SETUP.answer_for('Enter "YES" to proceed or "n"') == "n"
    assert SETUP.answer_for("Install a KWin script?") == "n"


def test_rewrites_nested_sudo_non_interactively(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(SETUP, "SUDO", "/trusted/sudo")

    assert SETUP.rewrite_sudo_argv(["sudo", "dnf", "install"]) == [
        "/trusted/sudo",
        "-n",
        "dnf",
        "install",
    ]
    assert SETUP.rewrite_sudo_argv(["/usr/bin/sudo", "-k"]) is None
    assert (
        SETUP.rewrite_sudo_shell("sudo -k; sudo tee /etc/example")
        == "true; /trusted/sudo -n tee /etc/example"
    )


def test_splits_rpm_ostree_live_install_into_supported_commands(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    calls: list[list[str]] = []

    def record_run(
        argv: list[str], *_args: object, **_kwargs: object
    ) -> subprocess.CompletedProcess[str]:
        calls.append(argv)
        return subprocess.CompletedProcess(argv, 0, "", "")

    monkeypatch.setattr(SETUP, "SUDO", "/trusted/sudo")
    monkeypatch.setattr(SETUP, "ORIGINAL_RUN", record_run)

    result = SETUP.automated_run(
        [
            "/usr/bin/sudo",
            "rpm-ostree",
            "install",
            "--idempotent",
            "--apply-live",
            "dbus-devel",
        ],
        check=True,
    )

    assert result.returncode == 0
    assert calls == [
        [
            "/trusted/sudo",
            "-n",
            "rpm-ostree",
            "install",
            "--idempotent",
            "dbus-devel",
        ],
        [
            "/trusted/sudo",
            "-n",
            "rpm-ostree",
            "apply-live",
            "--allow-replacement",
        ],
    ]
