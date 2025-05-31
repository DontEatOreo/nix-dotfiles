{ pkgs, ... }:
{
  services.kanata = {
    enable = true;
    package = pkgs.kanata-with-cmd;
    keyboards.main = {
      devices = [
        "/dev/input/by-id/usb-Ducky_Ducky_One2_Mini_RGB_DK-V1.09-201006-event-if03"
        "/dev/input/by-id/usb-Ducky_Ducky_One2_Mini_RGB_DK-V1.09-201006-event-kbd"
        "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8910_-event-kbd"
      ];
      extraDefCfg = "danger-enable-cmd yes process-unmapped-keys yes concurrent-tap-hold yes";
      config = builtins.readFile ./config.scm;
    };
  };
}
