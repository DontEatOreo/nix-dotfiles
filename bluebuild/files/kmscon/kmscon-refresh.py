#!/usr/bin/env python3.14

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

from kmscon_files import write_if_changed

LOGINCTL = "/usr/bin/loginctl"
SYSTEMCTL = "/usr/bin/systemctl"
KMSCON_TTYS = tuple(f"tty{number}" for number in range(1, 7))
DEFAULT_STATE = Path("/run/kmscon-theme-refresh.json")


def command_output(argv: tuple[str, ...]) -> str:
    return subprocess.run(
        argv,
        check=True,
        capture_output=True,
        text=True,
    ).stdout


def session_ids() -> tuple[str, ...]:
    output = command_output((LOGINCTL, "list-sessions", "--no-legend", "--no-pager"))
    return tuple(fields[0] for line in output.splitlines() if (fields := line.split()))


def session_tty(session_id: str) -> str | None:
    output = command_output((
        LOGINCTL,
        "show-session",
        session_id,
        "--property=TTY",
        "--property=VTNr",
    ))
    properties = dict(
        line.split("=", maxsplit=1) for line in output.splitlines() if "=" in line
    )
    tty = properties.get("TTY", "")
    if tty in KMSCON_TTYS:
        return tty
    vt_number = properties.get("VTNr", "")
    candidate = f"tty{vt_number}"
    return candidate if candidate in KMSCON_TTYS else None


def logged_in_ttys() -> set[str]:
    return {tty for session_id in session_ids() if (tty := session_tty(session_id))}


def config_digest(config: Path) -> str:
    return hashlib.sha256(config.read_bytes()).hexdigest()


def load_pending(state_path: Path, digest: str) -> set[str]:
    try:
        state = json.loads(state_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return set(KMSCON_TTYS)
    except OSError:
        return set(KMSCON_TTYS)
    if not isinstance(state, dict) or state.get("config_sha256") != digest:
        return set(KMSCON_TTYS)
    pending = state.get("pending_ttys")
    if not isinstance(pending, list):
        return set(KMSCON_TTYS)
    return {tty for tty in pending if tty in KMSCON_TTYS}


def write_state(state_path: Path, digest: str, pending: set[str]) -> None:
    content = json.dumps(
        {"config_sha256": digest, "pending_ttys": sorted(pending)},
        indent=2,
        sort_keys=True,
    )
    write_if_changed(state_path, f"{content}\n")


def refresh(config: Path, state_path: Path) -> int:
    digest = config_digest(config)
    pending = load_pending(state_path, digest)
    if not pending:
        return 0

    occupied = logged_in_ttys()
    remaining = pending & occupied
    failed = False
    for tty in sorted(pending - occupied):
        result = subprocess.run(
            (SYSTEMCTL, "try-restart", f"kmsconvt@{tty}.service"),
            check=False,
        )
        if result.returncode != 0:
            remaining.add(tty)
            failed = True

    write_state(state_path, digest, remaining)
    return 1 if failed else 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(suggest_on_error=True)
    parser.add_argument("config", type=Path)
    parser.add_argument("--state", type=Path, default=DEFAULT_STATE)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    return refresh(args.config, args.state)


if __name__ == "__main__":
    raise SystemExit(main())
