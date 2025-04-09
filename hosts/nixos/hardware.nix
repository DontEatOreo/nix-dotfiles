{
  pkgs,
  lib,
  config,
  ...
}:
{
  boot.extraModprobeConfig =
    "options nvidia "
    + lib.concatStringsSep " " [
      # NVIDIA assumes that by default your CPU doesn't support `PAT`, but this
      # is effectively never the case in 2023
      "NVreg_UsePageAttributeTable=1"
      # This is sometimes needed for ddc/ci support, see
      # https://www.ddcutil.com/nvidia/
      #
      # Current monitor does not support it, but this is useful for
      # the future
      "NVreg_RegistryDwords=RMUseSwI2c=0x01;RMI2cSpeed=100"
    ];

  environment.systemPackages = builtins.attrValues { inherit (pkgs) libva-utils; };
  environment.sessionVariables = {
    # Required to run the correct GBM backend for NVIDIA GPUs on Wayland
    GBM_BACKEND = "nvidia-drm";
    # Apparently, without this NOUVEAU may attempt to be used instead
    # (despite it being blacklisted)
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # Hardware cursors are currently broken on wlroots
    WLR_NO_HARDWARE_CURSORS = "1";

    NVD_BACKEND = "direct";
    LIBVA_DRIVER_NAME = "nvidia";

    # Improve compatibility for older Java GUI (AWT/Swing) apps, especially on
    # non-reparenting WMs (most Wayland compositors, some X11 WMs)
    _JAVA_AWT_WM_NONREPARENTING = "1";

    # Enable automatic scaling for Qt5/Qt6 applications based on monitor DPI
    # Useful for HiDPI displays
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";

    # Enable Variable Refresh Rate (VRR/G-Sync/FreeSync) for OpenGL and GLX
    __GL_VRR_ALLOWED = "1";
    __GLX_VRR_ALLOWED = "1";

    EGL_PLATFORM = "wayland";
  };

  hardware = {
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = builtins.attrValues {
        inherit (pkgs)
          amdvlk
          libva-vdpau-driver
          libvdpau-va-gl
          mesa
          nv-codec-headers-12
          vulkan-loader
          ;
      };
      extraPackages32 = builtins.attrValues {
        inherit (pkgs.pkgsi686Linux) libva-vdpau-driver libvdpau-va-gl mesa;
      };
    };

    nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest;
    nvidia.modesetting.enable = true;
  };
}
