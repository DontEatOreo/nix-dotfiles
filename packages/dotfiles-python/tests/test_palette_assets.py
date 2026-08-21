from workstation.local import gnome
from workstation.macos import appearance, terminal


def test_shared_palette_asset_consumers() -> None:
    assert gnome._accent_colors() == (
        ("#914669", "#f8f1f2"),
        ("#cf829a", "#100d14"),
    )
    assert appearance._accent() == "#914669"
    assert terminal._dark_palette()["text"] == "#eee5eb"
