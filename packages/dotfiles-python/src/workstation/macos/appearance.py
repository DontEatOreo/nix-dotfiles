"""Black Rose Doll integration with macOS appearance preferences."""

import sys
import warnings
from importlib import import_module
from typing import Any, cast

from pydantic import TypeAdapter

from workstation.lib.commands import run
from workstation.lib.paths import asset_path

APPLE_GRAPHITE_ACCENT = -1
OTHER_ICON_TINT = 10
SKYLIGHT = "/System/Library/PrivateFrameworks/SkyLight.framework"


def _accent() -> str:
    palette = TypeAdapter(dict[str, dict[str, str]]).validate_json(
        asset_path("desktop", "black_rose_doll_palette.json").read_text()
    )
    return palette["light"]["pink"]


def _components(color: str) -> tuple[float, float, float]:
    return (
        int(color[1:3], 16) / 255,
        int(color[3:5], 16) / 255,
        int(color[5:7], 16) / 255,
    )


def _preference_color(color: str, *, alpha: bool = False) -> str:
    channels = (*_components(color), 1.0) if alpha else _components(color)
    return " ".join(f"{channel:.6f}" for channel in channels)


def _apply_icon_tint(color: str) -> None:
    appkit = cast("Any", import_module("AppKit"))
    objc = cast("Any", import_module("objc"))
    objc.loadBundle("SkyLight", globals(), bundle_path=SKYLIGHT)
    configuration_class = objc.lookUpClass("SLSIconAppearanceConfiguration")
    configuration = configuration_class.fetchCurrentIconAppearanceConfiguration()
    red, green, blue = _components(color)
    tint = appkit.NSColor.colorWithSRGBRed_green_blue_alpha_(
        red,
        green,
        blue,
        1,
    )
    configuration.setIconTintColorName_(OTHER_ICON_TINT)
    with warnings.catch_warnings():
        warnings.simplefilter("ignore", objc.ObjCPointerWarning)
        configuration.setOtherIconTintColor_(tint.CGColor())
    configuration.save()


def _notify_color_change() -> None:
    foundation = cast("Any", import_module("Foundation"))
    center = foundation.NSDistributedNotificationCenter.defaultCenter()
    center.postNotificationName_object_userInfo_deliverImmediately_(
        "AppleColorPreferencesChangedNotification",
        None,
        None,
        True,
    )


def apply_appearance() -> None:
    """Apply the closest native accent and exact custom highlight/icon tint."""
    if sys.platform != "darwin":
        return
    accent = _accent()
    highlight = _preference_color(accent)
    run((
        "defaults",
        "write",
        "-g",
        "AppleAccentColor",
        "-int",
        str(APPLE_GRAPHITE_ACCENT),
    ))
    run((
        "defaults",
        "write",
        "-g",
        "AppleHighlightColor",
        "-string",
        f"{highlight} Other",
    ))
    run((
        "defaults",
        "write",
        "com.apple.systempreferences",
        "AppleOtherHighlightColor",
        "-string",
        highlight,
    ))
    _apply_icon_tint(accent)
    _notify_color_change()
