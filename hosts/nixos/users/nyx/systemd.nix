_: {
  systemd = {
    services = {
      # Set 60% Charging limit to "conserve" battery life
      conserveModeEnable = {
        description = "Enable Lenovo Conservation Mode";
        enable = true;
        script = "echo 1 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode";
        wantedBy = [ "default.target" ];
      };
      # Disable "Conserve" Mode and let battery charge to 100%;
      conserveModeDisable = {
        description = "Disable Lenovo Conservation Mode";
        enable = true;
        script = "echo 0 > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode";
        wantedBy = [ "default.target" ];
      };
    };
  };
}
