_: {
  services = {
    libinput = {
      enable = true;
    };
    xserver = {
      videoDrivers = [ "nvidia" ];
      xkb = {
        layout = "us";
      };
      enable = true;
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
      # Patch to fix usb-camera bug
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/2669
      # https://gitlab.freedesktop.org/pipewire/pipewire/-/issues/4115
      wireplumber.extraConfig = {
        "10-disable-camera" = {
          "wireplumber.profiles" = {
            main = {
              "monitor.libcamera" = "disabled";
            };
          };
        };
      };
    };
    xremap = {
      withGnome = true;
      serviceMode = "user";
      userName = "nyx";
      config = {
        keymap = [
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
          {
            name = "Ctrl+Up/Down for Start/End of Page";
            remap = {
              "Ctrl-Up" = "Ctrl-Home";
              "Ctrl-Down" = "Ctrl-End";
            };
          }
        ];
      };
    };
    # Temporarily disable until https://github.com/NixOS/nixpkgs/pull/331780 reaches unstable
    # ollama.enable = true;
  };
}
