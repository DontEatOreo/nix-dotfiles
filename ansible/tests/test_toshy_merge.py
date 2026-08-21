from importlib.util import module_from_spec, spec_from_file_location
from pathlib import Path

import pytest

SCRIPT = (
    Path(__file__).parents[1]
    / "roles"
    / "keyboard"
    / "files"
    / "toshy"
    / "merge-slices.py"
)
SPEC = spec_from_file_location("toshy_merge_slices", SCRIPT)
assert SPEC is not None
assert SPEC.loader is not None
MERGER = module_from_spec(SPEC)
SPEC.loader.exec_module(MERGER)


def marked(name: str, body: str) -> str:
    return (
        f"###  SLICE_MARK_START: {name}  ###\n{body}\n###  SLICE_MARK_END: {name}  ###"
    )


def test_restores_upstream_owned_slice_before_custom_merge() -> None:
    installed = "\n\n".join([
        marked("keymapper_api", "old dotfiles override"),
        marked("user_custom_functions", "old custom functions"),
    ])
    upstream = "\n\n".join([
        marked("keymapper_api", "new upstream API defaults"),
        marked("user_custom_functions", ""),
    ])

    merged = MERGER.merge_slices(
        installed,
        {"user_custom_functions": "new dotfiles extension\n"},
        upstream_config=upstream,
        reset_slices=["keymapper_api"],
    )

    assert "new upstream API defaults" in merged
    assert "old dotfiles override" not in merged
    assert "new dotfiles extension" in merged
    assert "old custom functions" not in merged


def test_rejects_slice_that_is_both_reset_and_managed() -> None:
    config = marked("keymapper_api", "body")

    with pytest.raises(SystemExit, match="both reset and dotfiles-managed"):
        MERGER.merge_slices(
            config,
            {"keymapper_api": "custom\n"},
            upstream_config=config,
            reset_slices=["keymapper_api"],
        )
