from __future__ import annotations

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
