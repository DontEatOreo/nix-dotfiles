{
  pkgs,
  lib,
  config,
  ...
}:
{
  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    graphics = {
      enable = true;
      # For Wine32 mostly
      enable32Bit = true;
      extraPackages = lib.attrValues {
        inherit (pkgs)
          mesa
          nvidia-vaapi-driver
          # For Encoding/Decoding Videos
          nv-codec-headers-12
          vulkan-loader
          ;
      };
      extraPackages32 = lib.attrValues { inherit (pkgs.driversi686Linux) mesa; };
    };
    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.production;
      # Modesetting is required.
      modesetting.enable = true;
    };
  };
}
