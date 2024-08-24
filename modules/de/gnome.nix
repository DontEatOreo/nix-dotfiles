{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.nixOS.gnome.enable = mkEnableOption "Enable GNOME";

  config = mkIf config.nixOS.gnome.enable {
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
    hardware.pulseaudio.enable = false;
    environment = {
      systemPackages = builtins.attrValues {
        inherit (pkgs) wl-clipboard;
        inherit (pkgs.gnomeExtensions) appindicator clipboard-indicator;
      };
      gnome.excludePackages =
        builtins.attrValues {
          inherit (pkgs)
            gnome-tour
            epiphany # Browser
            geary # Email
            evince # Docs
            ;
        }
        ++ builtins.attrValues { inherit (pkgs.gnome) gnome-maps gnome-weather gnome-music; };
    };
  };
}
