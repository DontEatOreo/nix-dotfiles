import json
import os


def _nd_env_list(name, default=None):
    value = os.environ.get(name)
    if value is None:
        return list(default or [])

    value = value.strip()
    if value == "" or value.casefold() in {"all", "auto", "none"}:
        return []

    if value.startswith("["):
        parsed = json.loads(value)
        if not isinstance(parsed, list) or not all(
            isinstance(item, str) for item in parsed
        ):
            raise ValueError(f"{name} must be a JSON array of strings")
        return parsed

    return [line.strip() for line in value.splitlines() if line.strip()]


# Keep upstream's keymapper API slice intact. These calls intentionally live in
# Toshy's user extension point and only override the values dotfiles owns.
timeouts(suspend=1)
devices_api(
    only_devices=_nd_env_list(
        "DOTFILES_TOSHY_ONLY_DEVICES",
        default=["/run/kanata-main/main"],
    ),
    ignore_devices=_nd_env_list("DOTFILES_TOSHY_IGNORE_DEVICES"),
)
