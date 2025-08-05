{ myLib, ... }:
let
  inherit (myLib) mkHomeRowModConfig mkLayerSwitch;

  leftHandKeys = [
    "q"
    "w"
    "e"
    "r"
    "t"
    "a"
    "s"
    "d"
    "f"
    "g"
    "z"
    "x"
    "c"
    "v"
    "b"
  ];

  rightHandKeys = [
    "y"
    "u"
    "i"
    "o"
    "p"
    "h"
    "j"
    "k"
    "l"
    "scln"
    "n"
    "m"
    ","
    "."
    "/"
  ];

  homeRowMods =
    mkHomeRowModConfig {
      keys = [
        "a"
        "s"
        "d"
        "f"
      ];
      mods = [
        "lmet"
        "lalt"
        "lctl"
        "lsft"
      ];
      behavior = "tap-hold-release-keys";
      releaseKeys = leftHandKeys;
    }
    // mkHomeRowModConfig {
      keys = [
        "j"
        "k"
        "l"
        "scln"
      ];
      mods = [
        "rsft"
        "rctl"
        "ralt"
        "rmet"
      ];
      behavior = "tap-hold";
    };
in
{
  services.kanata.keyboards.main.devices = [
    # Laptop built-in keyboard
    "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8910_-event-kbd"
    # External Keyboard (Ducky One 2 Mini Black)
    "/dev/input/by-id/usb-Ducky_Ducky_One2_Mini_RGB_DK-V1.09-201006-event-if03"
    "/dev/input/by-id/usb-Ducky_Ducky_One2_Mini_RGB_DK-V1.09-201006-event-kbd"
    # External Mouse (Logitech Lift)
    "/dev/input/by-id/usb-Logitech_USB_Receiver-if01-event-mouse"
    "/dev/input/by-id/usb-Logitech_USB_Receiver-event-kbd"
  ];

  nixos.kanata = {
    enable = true;
    config = {
      # Custom keycodes and source keys
      localKeys = {
        my_side_button = 275; # BTN_SIDE -> VolDown
        my_extra_button = 276; # BTN_EXTRA -> VolUp
      };

      sourceKeys = [
        "esc"
        "caps"
        "a"
        "s"
        "d"
        "f"
        "e"
        "h"
        "j"
        "k"
        "l"
        "scln"
        "o"
        "spc"
        "my_side_button"
        "my_extra_button"
      ];

      variables = {
        tap-timeout = 220;
        hold-timeout = 240;
        toggle-hold-time = 500;
        left-hand-keys = leftHandKeys;
        right-hand-keys = rightHandKeys;
      };

      aliases = [
        # Toggle modifiers on/off with 'o' key
        (mkLayerSwitch "o-mods-on" "o" "base-no-mods" 500 220)
        (mkLayerSwitch "o-mods-off" "o" "base" 500 220)
      ];

      layers = {
        # Base layer with home-row mods active.
        base = [
          "caps" # Swapped with esc
          "esc" # Swapped with caps
          "@a" # HRM
          "@s" # HRM
          "@d" # HRM
          "@f" # HRM
          "e"
          "h"
          "@j" # HRM
          "@k" # HRM
          "@l" # HRM
          "@scln" # HRM
          "@o-mods-on"
          "spc" # Normal space
          "vold"
          "volu"
        ];

        base-no-mods = [
          "caps"
          "esc"
          "a" # Normal key
          "s" # Normal key
          "d" # Normal key
          "f" # Normal key
          "e"
          "h"
          "j" # Normal key
          "k" # Normal key
          "l" # Normal key
          "scln" # Normal key
          "@o-mods-off"
          "spc"
          "vold"
          "volu"
        ];
      };

      helpers.mkHomeRowMods = homeRowMods;

      extraDefCfg = [
        "danger-enable-cmd yes"
        "process-unmapped-keys yes"
        "concurrent-tap-hold yes"
      ];
    };
  };
}
