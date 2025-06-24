{
  lib,
  config,
  pkgs,
  osConfig,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isDarwin;
  modKey = if isDarwin then "Super" else "Ctrl";
  copy_command = if isDarwin then "pbcopy" else "wl-copy";

  mkBind = key: action: {
    "bind \"${modKey} ${key}\"" = action;
  };

  mkShiftBind = key: action: {
    "bind \"${modKey} Shift ${key}\"" = action;
  };

  # (no modifier key)
  mkSimpleBind = key: action: {
    "bind \"${key}\"" = action;
  };

  # Direction mappings
  directions = {
    Up = "Up";
    Down = "Down";
    Left = "Left";
    Right = "Right";
  };

  directionKeys = {
    "Up" = "Up";
    "Down" = "Down";
    "Left" = "Left";
    "Right" = "Right";
  };

  mkDirectionalNav = lib.mkMerge (
    lib.mapAttrsToList (k: v: mkShiftBind k { MoveFocus = v; }) directions
  );

  mkDirectionalNewPane = lib.mkMerge (
    lib.mapAttrsToList (
      k: v:
      mkSimpleBind k {
        NewPane = v;
        SwitchToMode = "Normal";
      }
    ) directionKeys
  );

  mkDirectionalResize = lib.mkMerge (
    lib.mapAttrsToList (
      k: v:
      mkSimpleBind k {
        Resize = "Increase ${v}";
        SwitchToMode = "Normal";
      }
    ) directionKeys
  );

  mkModeSwitch = key: mode: mkBind key { SwitchToMode = mode; };
  mkQuit = key: mkBind key { Quit = { }; };
in
{
  options.hm.zellij.enable = lib.mkEnableOption "Zellij";

  config = lib.mkIf config.hm.zellij.enable {
    programs.zellij.enable = true;
    programs.zellij.settings = {
      default_shell = "${lib.getExe pkgs.nushell}";
      inherit copy_command;
      copy_clipboard = "system";
      copy_on_select = false;
      scrollback_editor = "hx";
      mirror_session = true;
      show_startup_tips = false;

      session = lib.mkMerge [
        (mkSimpleBind "d" {
          Detach = { };
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "w" {
          LaunchOrFocusPlugin = "session-manager";
          SwitchToMode = "Normal";
        })
        (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
      ];

      ui = {
        pane_frames = {
          rounded_corners = true;
          hide_session_name = false;
        };
      };

      default_layout = "compact";

      plugins = {
        tab-bar = {
          path = "tab-bar";
        };
        strider = {
          path = "strider";
        };
        compact-bar = {
          path = "compact-bar";
        };
        session-manager = {
          path = "session-manager";
        };
        status-bar = {
          path = "status-bar";
        };
      };

      keybinds = {
        normal = lib.mkMerge [
          (mkBind "t" { NewTab = { }; }) # New tab
          (mkBind "k" { Clear = { }; }) # Clear pane text
          (mkShiftBind "Backspace" { CloseFocus = { }; }) # Close pane

          (mkBind "c" { Copy = { }; })

          # Tab switching
          (mkBind "1" { GoToTab = 1; })
          (mkBind "2" { GoToTab = 2; })
          (mkBind "3" { GoToTab = 3; })
          (mkBind "4" { GoToTab = 4; })
          (mkBind "5" { GoToTab = 5; })
          (mkBind "6" { GoToTab = 6; })
          (mkBind "7" { GoToTab = 7; })
          (mkBind "8" { GoToTab = 8; })
          (mkBind "9" { GoToTab = 9; })

          # Super+Shift+direction
          mkDirectionalNav

          (mkModeSwitch "g" "Locked")
          (mkShiftBind "r" { SwitchToMode = "Resize"; }) # Resize mode
          (mkShiftBind "s" { SwitchToMode = "Pane"; }) # Pane mode
          (mkModeSwitch "s" "Search")
          (mkModeSwitch "o" "Session")
          (mkQuit "q")
        ];

        # Pane mode (Super+Shift+s > direction)
        pane = lib.mkMerge [
          mkDirectionalNewPane
          (mkSimpleBind "p" { SwitchFocus = { }; })
          (mkSimpleBind "x" {
            CloseFocus = { };
            SwitchToMode = "Normal";
          })
          (mkSimpleBind "f" {
            ToggleFocusFullscreen = { };
            SwitchToMode = "Normal";
          })
          (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
        ];

        # Resize mode (Super+Shift+r > direction)
        resize = lib.mkMerge [
          mkDirectionalResize
          (mkSimpleBind "=" {
            Resize = "Increase";
            SwitchToMode = "Normal";
          })
          (mkSimpleBind "-" {
            Resize = "Decrease";
            SwitchToMode = "Normal";
          })
          (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
        ];

        locked = mkModeSwitch "g" "Normal";

        search = lib.mkMerge [
          (mkSimpleBind "/" {
            SwitchToMode = "EnterSearch";
            SearchInput = 0;
          })
          (mkSimpleBind "n" { Search = "down"; })
          (mkSimpleBind "N" { Search = "up"; })
          (mkSimpleBind "c" { SearchToggleOption = "CaseSensitivity"; })
          (mkSimpleBind "w" { SearchToggleOption = "WholeWord"; })
          (mkSimpleBind "e" {
            EditScrollback = { };
            SwitchToMode = "Normal";
          })
          (mkSimpleBind "Esc" { SwitchToMode = "Normal"; })
        ];
      };
    };
  };
}
