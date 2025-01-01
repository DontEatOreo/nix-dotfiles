{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  isLinux = builtins.match ".*linux.*" system != null;
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
