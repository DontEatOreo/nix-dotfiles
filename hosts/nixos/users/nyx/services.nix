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
    };
    xremap = {
      withKDE = true;
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
