import json
from pathlib import Path

import pytest

REPOSITORY = Path(__file__).parents[2]
PALETTE = REPOSITORY / "dotfiles/.chezmoitemplates/black_rose_doll_palette.json"
TEXT_ROLES = {
    "blue",
    "flamingo",
    "foam",
    "gold",
    "green",
    "iris",
    "lavender",
    "love",
    "maroon",
    "mauve",
    "muted",
    "overlay2",
    "peach",
    "pine",
    "pink",
    "red",
    "rose",
    "rosewater",
    "sapphire",
    "sky",
    "subtext0",
    "subtext1",
    "teal",
    "text",
    "yellow",
}


def relative_luminance(color: str) -> float:
    channels = [int(color[index : index + 2], 16) / 255 for index in (1, 3, 5)]
    linear = [
        channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4
        for channel in channels
    ]
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast_ratio(foreground: str, background: str) -> float:
    lighter, darker = sorted(
        (relative_luminance(foreground), relative_luminance(background)),
        reverse=True,
    )
    return (lighter + 0.05) / (darker + 0.05)


@pytest.mark.parametrize("variant", ["light", "dark"])
def test_black_rose_doll_text_roles_meet_wcag_aa(variant: str) -> None:
    palette = json.loads(PALETTE.read_text(encoding="utf-8"))[variant]

    failing = {
        role: contrast_ratio(palette[role], palette["base"])
        for role in TEXT_ROLES
        if contrast_ratio(palette[role], palette["base"]) < 4.5
    }

    assert failing == {}


@pytest.mark.parametrize("variant", ["light", "dark"])
def test_black_rose_doll_selection_preserves_text_contrast(variant: str) -> None:
    palette = json.loads(PALETTE.read_text(encoding="utf-8"))[variant]

    assert contrast_ratio(palette["text"], palette["highlightMed"]) >= 4.5
