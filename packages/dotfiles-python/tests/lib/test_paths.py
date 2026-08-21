from pathlib import Path
from typing import TYPE_CHECKING

from workstation.lib import paths

if TYPE_CHECKING:
    import pytest


def test_installed_assets_do_not_require_a_repository(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
) -> None:
    installed = tmp_path / "share/dotfiles-python"
    installed.mkdir(parents=True)

    def no_repository() -> Path:
        raise FileNotFoundError

    monkeypatch.setattr(paths, "installed_data_roots", lambda: (installed,))
    monkeypatch.setattr(paths, "repository_root", no_repository)
    paths.assets_root.cache_clear()

    try:
        assert paths.assets_root() == installed
    finally:
        paths.assets_root.cache_clear()
