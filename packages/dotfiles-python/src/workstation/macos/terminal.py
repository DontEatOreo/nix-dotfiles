"""Apple Terminal profile provisioning."""

import sys
from importlib import import_module

from pydantic import TypeAdapter

from workstation.lib.paths import asset_path


def _palettes() -> dict[str, dict[str, str]]:
    data = TypeAdapter(dict[str, dict[str, dict[str, str]]]).validate_json(
        asset_path("desktop", "t3_chat_palette.json").read_text()
    )
    return data["t3_chat"]


def terminal_profile() -> None:
    """Install the T3 Chat light and dark profiles in Terminal.app."""
    if sys.platform != "darwin":
        return
    appkit = import_module("AppKit")
    foundation = import_module("Foundation")
    ns_color = getattr(appkit, "NSColor")
    ns_font = getattr(appkit, "NSFont")
    ns_keyed_archiver = getattr(foundation, "NSKeyedArchiver")
    ns_user_defaults = getattr(foundation, "NSUserDefaults")

    def archived(value: object) -> object:
        return ns_keyed_archiver.archivedDataWithRootObject_(value)

    def color(value: str) -> object:
        red, green, blue = bytes.fromhex(value.removeprefix("#"))
        return archived(
            ns_color.colorWithSRGBRed_green_blue_alpha_(
                red / 255,
                green / 255,
                blue / 255,
                1,
            )
        )

    palettes = _palettes()
    font = ns_font.fontWithName_size_("JetBrainsMonoNFM-Regular", 15)
    if font is None:
        font = ns_font.monospacedSystemFontOfSize_weight_(15, 0)

    ansi_roles = (
        "ansiBlack",
        "red",
        "green",
        "yellow",
        "blue",
        "mauve",
        "teal",
        "ansiWhite",
        "mutedForeground",
        "red",
        "green",
        "yellow",
        "blue",
        "mauve",
        "teal",
        "ansiWhite",
    )
    keys = (
        "ANSIBlackColor",
        "ANSIRedColor",
        "ANSIGreenColor",
        "ANSIYellowColor",
        "ANSIBlueColor",
        "ANSIMagentaColor",
        "ANSICyanColor",
        "ANSIWhiteColor",
        "ANSIBrightBlackColor",
        "ANSIBrightRedColor",
        "ANSIBrightGreenColor",
        "ANSIBrightYellowColor",
        "ANSIBrightBlueColor",
        "ANSIBrightMagentaColor",
        "ANSIBrightCyanColor",
        "ANSIBrightWhiteColor",
    )

    def profile(variant: str) -> tuple[str, dict[str, object]]:
        palette = palettes[variant]
        name = f"T3 Chat {variant.title()}"
        values: dict[str, object] = {
            "name": name,
            "type": "Window Settings",
            "ProfileCurrentVersion": 2.09,
            "columnCount": 120,
            "rowCount": 30,
            "Font": archived(font),
            "FontAntialias": True,
            "FontHeightSpacing": 1,
            "FontWidthSpacing": 1,
            "BackgroundBlur": 0,
            "BackgroundBlurInactive": 0,
            "BackgroundSettingsForInactiveWindows": False,
            "DynamicANSIForegroundColors": False,
            "TextColor": color(palette["terminalForeground"]),
            "TextBoldColor": color(palette["terminalCursor"]),
            "BackgroundColor": color(palette["terminalBackground"]),
            "CursorColor": color(palette["terminalCursor"]),
            "SelectionColor": color(palette["terminalSelection"]),
        }
        values.update({
            key: color(palette[role])
            for key, role in zip(keys, ansi_roles, strict=True)
        })
        return name, values

    defaults = ns_user_defaults.standardUserDefaults()
    domain = dict(defaults.persistentDomainForName_("com.apple.Terminal") or {})
    settings = dict(domain.get("Window Settings") or {})
    settings.pop("Black Rose Doll Dark", None)
    settings.pop("T3 Chat", None)
    for variant in ("light", "dark"):
        name, values = profile(variant)
        settings[name] = values
    current_variant = (
        "Dark" if defaults.stringForKey_("AppleInterfaceStyle") == "Dark" else "Light"
    )
    default_name = f"T3 Chat {current_variant}"
    domain.update({
        "Window Settings": settings,
        "Default Window Settings": default_name,
        "Startup Window Settings": default_name,
        "DefaultProfilesVersion": 2,
        "ProfileCurrentVersion": 2.09,
    })
    defaults.setPersistentDomain_forName_(domain, "com.apple.Terminal")
