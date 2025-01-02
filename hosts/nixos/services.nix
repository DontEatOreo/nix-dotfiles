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
  };
}
