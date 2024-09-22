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
      # Patch to fix usb-camera bug
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2669
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/4115
      "10-disable-camera" = {
        "wireplumber.profiles" = {
          main = {
            "monitor.libcamera" = "disabled";
          };
        };
      };
    };
  };
}
