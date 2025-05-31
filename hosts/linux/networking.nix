{ config, ... }:
{
  sops.secrets.wireless.neededForUsers = true;

  networking = {
    hostName = "lenovo-legion";
    networkmanager = {
      enable = true;
      ensureProfiles.environmentFiles = [ config.sops.secrets.wireless.path ];
      ensureProfiles.profiles = {
        ethernet = {
          connection = {
            id = "ethernet";
            type = "ethernet";
            master = "bond0";
            slave-type = "bond";
          };
          ipv4.method = "auto";
        };
        "2ghz" = {
          connection = {
            id = "2ghz";
            type = "wifi";
          };
          ipv4.method = "auto";
          wifi = {
            mode = "infrastructure";
            ssid = "2ghz";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PSK_HOME";
          };
        };

        "5ghz" = {
          connection = {
            id = "5ghz";
            type = "wifi";
            autoconnect = true;
            autoconnect-priority = 100;
          };
          ipv4.method = "auto";
          wifi = {
            mode = "infrastructure";
            ssid = "5ghz";
          };
          wifi-security = {
            key-mgmt = "wpa-psk";
            psk = "$PSK_HOME";
          };
        };
      };
    };
  };
}
