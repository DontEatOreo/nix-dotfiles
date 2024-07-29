{ pkgs, ... }:
{
  services.xserver = {
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
}
