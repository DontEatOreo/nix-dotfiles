{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (config.nixpkgs.hostPlatform) isLinux;
in
{
  options.nixOS.gnome.enable = lib.mkEnableOption "GNOME";

  config = lib.mkIf config.nixOS.gnome.enable {
    assertions = [
      {
        assertion = isLinux;
        message = "You cannot use GNOME on macOS";
      }
    ];
    services.xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
    };
    services.pulseaudio.enable = false;
    environment = {
      systemPackages = builtins.attrValues {
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
      gnome.excludePackages = builtins.attrValues {
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
    };
  };
}
