{
  config,
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.extraModulePackages = [ ];
  boot.initrd.availableKernelModules = lib.splitString " " "nvme xhci_pci ahci usbhid";
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/c91ba7a8-ef5c-494c-b9b0-2e6981f1bfd5";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "systemd-1";
    fsType = "autofs";
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/5546ec59-1370-419a-8e41-b36743f4f292"; } ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
