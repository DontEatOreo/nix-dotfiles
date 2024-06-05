_: {
  services = {
    libinput = {
      enable = true;
    };
    displayManager.sddm = {
      enable = true;
    };
    xserver = {
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us";
      };
      enable = true;
      # KDE
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
