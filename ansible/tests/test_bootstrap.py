import os
from pathlib import Path
from subprocess import CompletedProcess, run

import pytest

SIMULATOR = Path(__file__).with_name("bootstrap-simulate.sh")
BOOTSTRAP = SIMULATOR.parents[1] / "bootstrap.sh"
REPOSITORY_ROOT = SIMULATOR.parents[2]
GENERATED_DIRECTORIES = frozenset({
    ".ansible",
    ".direnv",
    ".git",
    ".pytest_cache",
    ".ruff_cache",
    ".venv",
    "__pycache__",
    "build",
    "dist",
    "node_modules",
    "zig-pkg",
})


def simulate(
    scenario: str,
    environment: dict[str, str] | None = None,
) -> CompletedProcess[str]:
    return run(
        [SIMULATOR, scenario],
        check=False,
        capture_output=True,
        env=None if environment is None else {**os.environ, **environment},
        text=True,
    )


def assert_in_order(output: str, expected: tuple[str, ...]) -> None:
    position = 0
    for value in expected:
        position = output.index(value, position) + len(value)


def test_setup_simulation_runs_every_phase_once_in_order() -> None:
    result = simulate("success")

    assert result.returncode == 0, result.stderr
    assert_in_order(
        result.stdout,
        (
            "homebrew-installer NONINTERACTIVE=1",
            "brew install --formula uv",
            "uv --no-config python install 3.14",
            "uv --no-config tool install",
            "ansible-galaxy collection install",
            (
                "ansible-playbook ANSIBLE_BECOME_ASK_PASS=false ansible/site.yml "
                "--tags stage-10,stage-20"
            ),
            "sops decrypt",
            (
                "ansible-playbook ANSIBLE_BECOME_ASK_PASS=false ansible/site.yml "
                "--tags stage-30"
            ),
            "just --justfile",
            (
                "ansible-playbook ANSIBLE_BECOME_ASK_PASS=false ansible/site.yml "
                "--tags host"
            ),
        ),
    )
    assert "--collections-path" in result.stdout
    assert "--force" in result.stdout
    assert result.stdout.count("--tags stage-10,stage-20") == 1
    assert result.stdout.count("--tags stage-30") == 1
    assert result.stdout.count("just --justfile") == 1
    assert result.stdout.count("--tags host") == 1


def test_existing_homebrew_skips_installer_but_refreshes_bootstrap_tools() -> None:
    result = simulate("existing-homebrew")

    assert result.returncode == 0, result.stderr
    assert "curl " not in result.stdout
    assert "homebrew-installer" not in result.stdout
    assert_in_order(
        result.stdout,
        (
            "brew --prefix",
            "brew install --formula uv",
            "uv --no-config python install 3.14",
            (
                "ansible-playbook ANSIBLE_BECOME_ASK_PASS=false ansible/site.yml "
                "--tags host"
            ),
        ),
    )


def test_ansible_arguments_are_forwarded_without_setup_orchestration() -> None:
    result = simulate("ansible-args")

    assert result.returncode == 0, result.stderr
    assert (
        "ansible-playbook ANSIBLE_BECOME_ASK_PASS=false ansible/site.yml "
        "--check --tags tools"
    ) in result.stdout
    assert "just --justfile" not in result.stdout
    assert "--tags stage-10,stage-20" not in result.stdout
    assert "--tags stage-30" not in result.stdout
    assert "--tags host" not in result.stdout


@pytest.mark.parametrize("ask_pass", ["true", "false"])
def test_explicit_ansible_become_setting_is_preserved(ask_pass: str) -> None:
    result = simulate(
        "ansible-args",
        {"ANSIBLE_BECOME_ASK_PASS": ask_pass},
    )

    assert result.returncode == 0, result.stderr
    assert f"ANSIBLE_BECOME_ASK_PASS={ask_pass}" in result.stdout


def test_failure_simulation_cannot_open_host_applications() -> None:
    result = simulate("secrets-failure")

    assert result.returncode == 1
    assert "open " not in result.stdout
    assert "run --setup interactively" in result.stderr


@pytest.mark.parametrize(
    ("scenario", "status", "failed_command", "blocked_command"),
    [
        ("download-failure", 1, "curl ", "brew --prefix"),
        ("checksum-failure", 1, "curl ", "homebrew-installer"),
        ("formula-failure", 1, "brew install --formula uv", "uv --no-config"),
        ("python-failure", 1, "python install 3.14", "tool install"),
        ("tool-failure", 1, "tool install", "ansible-galaxy"),
        (
            "collections-failure",
            1,
            "ansible-galaxy collection install",
            "--tags stage-10,stage-20",
        ),
        (
            "userland-failure",
            21,
            "--tags stage-10,stage-20",
            "sops decrypt",
        ),
        ("secrets-failure", 1, "sops decrypt", "--tags stage-30"),
        ("apply-failure", 22, "just --justfile", "--tags host"),
        ("missing-just", 1, "--tags stage-10,stage-20", "sops decrypt"),
    ],
)
def test_setup_simulation_stops_at_failed_phase(
    scenario: str,
    status: int,
    failed_command: str,
    blocked_command: str,
) -> None:
    result = simulate(scenario)

    assert result.returncode == status
    assert failed_command in result.stdout
    assert blocked_command not in result.stdout


def test_old_macos_is_rejected_before_host_changes() -> None:
    result = simulate("old-macos")

    assert result.returncode == 1
    assert "curl " not in result.stdout
    assert result.stderr == "error: macOS 26 or newer is required; found 25.6\n"


def test_host_failure_status_is_propagated_after_host_phase_starts() -> None:
    result = simulate("host-failure")

    assert result.returncode == 23
    assert "--tags host" in result.stdout
    assert "Simulation exit status: 23" in result.stdout


def test_setup_rejects_extra_ansible_arguments_before_changing_host() -> None:
    result = run(
        [BOOTSTRAP, "--setup", "--check"],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 1
    assert not result.stdout
    assert result.stderr == (
        "error: --setup does not accept additional Ansible arguments\n"
    )


def test_help_does_not_bootstrap_host() -> None:
    result = run(
        [BOOTSTRAP, "--help"],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0
    assert not result.stderr
    assert "ansible/bootstrap.sh --setup" in result.stdout


def test_unknown_simulation_scenario_is_rejected() -> None:
    result = simulate("unknown")

    assert result.returncode == 64
    assert not result.stdout
    assert result.stderr.startswith("usage:")
    assert "success|existing-homebrew" in result.stderr


@pytest.mark.parametrize(
    ("operating_system", "architecture", "expected_prefix"),
    [
        ("Darwin", "arm64", "/opt/homebrew"),
        ("Linux", "x86_64", "/home/linuxbrew/.linuxbrew"),
    ],
)
def test_homebrew_prefix_policy(
    operating_system: str,
    architecture: str,
    expected_prefix: str,
) -> None:
    result = run(
        [
            "/bin/bash",
            "-c",
            'source "$1"; resolve_homebrew_prefix "$2" "$3"',
            "bootstrap-test",
            BOOTSTRAP,
            operating_system,
            architecture,
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 0, result.stderr
    assert result.stdout == f"{expected_prefix}\n"


def test_rosetta_is_rejected_before_bootstrap() -> None:
    result = run(
        [
            "/bin/bash",
            "-c",
            'source "$1"; resolve_homebrew_prefix Darwin x86_64',
            "bootstrap-test",
            BOOTSTRAP,
        ],
        check=False,
        capture_output=True,
        text=True,
    )

    assert result.returncode == 1
    assert not result.stdout
    assert "native arm64 terminal, not Rosetta" in result.stderr


def test_every_bash_script_declares_its_shellcheck_dialect() -> None:
    missing_directive: list[str] = []

    for directory, child_directories, filenames in os.walk(REPOSITORY_ROOT):
        child_directories[:] = [
            name for name in child_directories if name not in GENERATED_DIRECTORIES
        ]
        for filename in filenames:
            path = Path(directory, filename)
            if not path.is_file():
                continue
            with path.open("rb") as source_file:
                shebang = source_file.readline()
                shellcheck_directive = source_file.readline().rstrip(b"\r\n")
            if not shebang.startswith(b"#!") or b"bash" not in shebang:
                continue
            if shellcheck_directive != b"# shellcheck shell=bash":
                missing_directive.append(str(path.relative_to(REPOSITORY_ROOT)))

    assert not missing_directive
