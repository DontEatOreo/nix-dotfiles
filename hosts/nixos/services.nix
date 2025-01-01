{ username, ... }:
{
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
    xremap = {
      withGnome = true;
      serviceMode = "user";
      userName = username;
      config = {
        keymap = [
          {
            name = "Swap CapsLock and Escape Keys";
            remap = {
              "CapsLock" = "Esc";
              "Esc" = "CapsLock";
            };
          }
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
  };
}
