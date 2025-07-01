_: {
  networking.networkmanager.enable = true;
  networking.networkmanager.ensureProfiles.profiles.ethernet = {
    connection = {
      id = "ethernet";
      type = "ethernet";
      master = "bond0";
      slave-type = "bond";
    };
    ipv4.method = "auto";
  };
}
