_: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    audio.enable = true; # Enable Pipewire as PRIMARY audio server
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    wireplumber.extraConfig = {
      # Fixes the "Corsair HS80 Wireless" Volume desync between Headset & System
      "volume-sync" = {
        "bluez5.enable-hw-volume" = false;
      };
    };
  };
}
