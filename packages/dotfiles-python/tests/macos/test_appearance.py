from workstation.macos.appearance import _components, _preference_color


def test_components_convert_srgb_hex_to_normalized_channels() -> None:
    assert _components("#914669") == (145 / 255, 70 / 255, 105 / 255)


def test_preference_color_uses_macos_component_format() -> None:
    assert _preference_color("#914669") == "0.568627 0.274510 0.411765"
    assert _preference_color("#914669", alpha=True) == (
        "0.568627 0.274510 0.411765 1.000000"
    )
