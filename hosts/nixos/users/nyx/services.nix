_: {
  services = {
    xserver = {
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us";
      };
      enable = true;
      libinput.enable = true; # Enable Touchpad support
      # KDE
      displayManager.sddm = {
        enable = true;
        settings.General.DisplayServer = "x11-user";
      };
      desktopManager.plasma5.enable = true;
    };
    openssh = {
      enable = true;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
