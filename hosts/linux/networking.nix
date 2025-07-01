{ config, ... }:
{
  sops.secrets.wireless.neededForUsers = true;

  networking = {
    hostName = "lenovo-legion";
    networkmanager = {
      ensureProfiles.environmentFiles = [ config.sops.secrets.wireless.path ];
      ensureProfiles.profiles = {
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
