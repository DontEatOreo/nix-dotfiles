from workstation.local.gnome import _accent_colors, _gtk_accent_css


def test_black_rose_doll_gtk_accents_include_contrasting_foregrounds() -> None:
    light, dark = _accent_colors()

    assert light == ("#914669", "#f8f1f2")
    assert dark == ("#cf829a", "#100d14")

    for gtk_version in (3, 4):
        for accent, foreground in (light, dark):
            css = _gtk_accent_css(accent, foreground, gtk_version=gtk_version)
            assert accent in css
            assert foreground in css
            assert "@accent@" not in css
            assert "@accent_fg@" not in css
