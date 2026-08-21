import importlib.util
import sys
from pathlib import Path
from types import ModuleType
from typing import Any, cast

import pytest


def _selinux_module() -> ModuleType:
    path = (
        Path(__file__).parents[1] / "roles/system/library/dotfiles_selinux_service.py"
    )
    spec = importlib.util.spec_from_file_location("dotfiles_selinux_service", path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"could not load {path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


selinux = cast("Any", _selinux_module())


def test_policy_state_detects_external_module_replacement(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    package = tmp_path / "example.pp"
    package.write_bytes(b"policy package")
    desired = "sha256:desired"
    monkeypatch.setattr(selinux, "package_checksum", lambda _package: desired)
    monkeypatch.setattr(
        selinux,
        "output",
        lambda _argv: f"example {desired}\nother sha256:other",
    )

    assert not selinux.policy_stale(package, "example")

    monkeypatch.setattr(
        selinux,
        "output",
        lambda _argv: "example sha256:externally-replaced",
    )
    assert selinux.policy_stale(package, "example")


def test_reconcile_defers_changes_while_protected_child_is_active(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setattr(selinux, "selinux_enabled", lambda: True)
    state = selinux.ConfinementState(
        package=tmp_path / "example.pp",
        unit="example.service",
        expected_context="system_u:system_r:example_t:s0",
        dropin=tmp_path / "dropin",
        dropin_content="content",
        policy_stale=True,
        dropin_stale=False,
        context="system_u:system_r:example_t:s0",
        restart_required=True,
    )
    monkeypatch.setattr(selinux, "confinement_state", lambda *_args: state)
    monkeypatch.setattr(selinux, "matching_child_active", lambda *_args: True)

    config = selinux.ReconcileConfig(
        policy_module="example",
        policy_directory=tmp_path,
        service="example",
        domain="example_t",
        restore_targets=(),
        restart_when_inactive=True,
        defer_child_pattern="protected child",
        allow_reload=False,
    )
    result = selinux.reconcile(
        config,
        check_mode=False,
    )

    assert not result.changed
    assert result.deferred
    assert result.enabled


def test_reconcile_check_mode_does_not_apply_changes(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    config = selinux.ReconcileConfig(
        policy_module="example",
        policy_directory=tmp_path,
        service="example",
        domain="example_t",
        restore_targets=(),
        restart_when_inactive=True,
        defer_child_pattern=None,
        allow_reload=False,
    )
    state = selinux.ConfinementState(
        package=tmp_path / "example.pp",
        unit="example.service",
        expected_context="system_u:system_r:example_t:s0",
        dropin=tmp_path / "dropin",
        dropin_content="content",
        policy_stale=True,
        dropin_stale=True,
        context="",
        restart_required=True,
    )
    monkeypatch.setattr(selinux, "selinux_enabled", lambda: True)
    monkeypatch.setattr(selinux, "confinement_state", lambda *_args: state)
    monkeypatch.setattr(selinux, "matching_child_active", lambda *_args: False)
    monkeypatch.setattr(
        selinux,
        "apply_confinement",
        lambda *_args: pytest.fail("check mode mutated the host"),
    )

    result = selinux.reconcile(config, check_mode=True)

    assert result.changed
    assert not result.deferred
