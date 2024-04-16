_: {
  services = {
    desktopManager.plasma6.enable = true;
    xserver = {
      videoDrivers = ["nvidia"];
      xkb = {
        layout = "us";
      };
      enable = true;
      libinput.enable = true; # Enable Touchpad support
      # KDE
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
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
