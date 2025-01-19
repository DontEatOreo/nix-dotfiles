{ config, ... }:
{
  hardware = {
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;

    graphics.enable = true;
    graphics.enable32Bit = true;

    nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest;
    # Modesetting is required.
    nvidia.modesetting.enable = true;
  };
}
