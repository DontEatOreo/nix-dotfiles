{
  pkgs,
  lib,
  config,
  ...
}:
let
  generateKeybindings =
    prefix: super: modifiers: range:
    builtins.listToAttrs (
      builtins.genList (
        x:
        let
          num = toString (x + 1);
          modifierStr = builtins.concatStringsSep "" modifiers;
        in
        {
          name = "${prefix}-${num}";
          value = [ "${super}${modifierStr}${num}" ];
        }
      ) range
    );
in
{
  options.nixOS.gnome.enable = lib.mkEnableOption "GNOME";
  options.nixOS.dconf.enable = lib.mkEnableOption "Dconf";

  config = lib.mkMerge [
    (lib.mkIf config.nixOS.gnome.enable {
      services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      environment.systemPackages = builtins.attrValues {
        inherit (pkgs) wl-clipboard;
        inherit (pkgs)
          apostrophe # Markdown Editor
          decibels # Audio Player
          gnome-obfuscate # Censor Private Info
          loupe # Image Viewer
          mousai # Shazam-like
          resources # Task Manager
          textpieces
          ;
        inherit (pkgs.gnomeExtensions) appindicator clipboard-indicator;
      };
      environment.gnome.excludePackages = builtins.attrValues {
        inherit (pkgs)
          gnome-maps
          gnome-music
          gnome-tour
          gnome-weather
          epiphany # Browser
          geary # Email
          evince # Docs
          ;
      };
    })
    (lib.mkIf config.nixOS.dconf.enable {
      programs.dconf.profiles.user.databases = [
        {
          lockAll = true; # Prevents overriding
          settings = {
            "org/gnome/desktop/interface" = {
              gtk-enable-primary-paste = false;
              enable-animations = false;
              clock-show-date = true;
              clock-show-seconds = true;
              clock-format = "24h";
            };

            "org/gnome/desktop/wm/preferences" = {
              num-workspaces = 9;
              button-layout = "close,minimize,maximize:";
              resize-with-right-button = true;
            };

            /*
              For some reason, `switch-to-workplace` will also assign
              `switch-to-application`, which we do not want as it breaks
              everything, so we have to explicitly set it to nothing
            */
            "org/gnome/shell/keybindings" =
              let
                otherKeybindings = { };
                switchKeybindings = (
                  lib.genAttrs (map (n: "switch-to-application-${toString n}") (lib.range 1 9)) (_: [ ])
                );
              in
              lib.mkMerge [
                otherKeybindings
                switchKeybindings
              ];

            "org/gnome/mutter/keybindings" = {
              toggle-tiled-left = [ "<Super>a" ];
              toggle-tiled-right = [ "<Super>d" ];
              move-to-center = [ "<Super>Return" ];
            };

            "org/gnome/desktop/wm/keybindings" =
              let
                otherKeybindings = {
                  maximize = [ "<Super><Shift>Return" ];
                  move-to-side-n = [ "<Super>w" ];
                  move-to-side-s = [ "<Super>s" ];
                };
                switchKeybindings = generateKeybindings "switch-to-workspace" "<Super>" [ ] 9;
                moveKeybindings = generateKeybindings "move-to-workspace" "<Super>" [ "<Shift>" ] 9;
              in
              lib.mkMerge [
                otherKeybindings
                switchKeybindings
                moveKeybindings
              ];

            "org/gnome/shell/app-switcher" = {
              current-workspace-only = false;
            };

            "org/gnome/shell" = {
              enabled-extensions = [
                "appindicatorsupport@rgcjonas.gmail.com"
                "places-menu@gnome-shell-extensions.gcampax.github.com"
                "clipboard-indicator@tudmotu.com"
                "system-monitor@gnome-shell-extensions.gcampax.github.com"
                "light-style@gnome-shell-extensions.gcampax.github.com"
              ];
            };
          };
        }
      ];
    })
  ];
}
