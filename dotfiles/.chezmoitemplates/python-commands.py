import os
import shutil
from pathlib import Path

ANSIBLE_PLAYBOOK_PROVIDERS = (
    ("ansible-playbook", ()),
    ("uvx", ("--from", "ansible-core", "ansible-playbook")),
)


def find_executable(name: str, preferred: Path | None = None) -> Path | None:
    located = shutil.which(name)
    candidates = (preferred, Path(located) if located else None)
    return next(
        (
            candidate
            for candidate in candidates
            if candidate is not None
            and candidate.is_file()
            and os.access(candidate, os.X_OK)
        ),
        None,
    )


def ansible_playbook_command() -> tuple[str, ...] | None:
    return next(
        (
            (executable, *arguments)
            for name, arguments in ANSIBLE_PLAYBOOK_PROVIDERS
            if (executable := shutil.which(name)) is not None
        ),
        None,
    )
