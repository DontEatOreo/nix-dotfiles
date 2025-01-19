_: {
  services = {
    libinput.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
    };
    openssh.enable = true;
  };
}
