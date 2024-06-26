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
      audio.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    xremap.config.keymap = [
      {
        name = "Ctrl+Arrows for Start/End of Line";
        remap = {
          "Ctrl-Left" = "Home";
          "Ctrl-Right" = "End";
        };
      }
      {
        name = "Alt+Arrows for Jumping Between Words";
        remap = {
          "Alt-Left" = "Ctrl-Left";
          "Alt-Right" = "Ctrl-Right";
        };
      }
    ];
  };
}
