_: {
  services = {
    libinput.enable = true;
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      xkb.layout = "us";
    };
    openssh.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true; # IPv4
      publish = {
        enable = true;
        addresses = true;
        domain = true;
        hinfo = true;
        userServices = true;
        workstation = true;
      };
    };
  };
}
