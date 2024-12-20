{
  system,
  inputs,
  config,
  lib,
  ...
}:
let
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.shared.nixpkgs = {
    enable = lib.mkEnableOption "Enable Nixpkgs";
    cudaSupport = lib.mkEnableOption "Enable Cuda";
  };

  config = lib.mkIf config.shared.nixpkgs.enable {
    nixpkgs = {
      config = {
        allowUnfree = true;
        cudaSupport = config.shared.nixpkgs.cudaSupport;
      };
      hostPlatform = system;
      overlays = [
        inputs.catppuccin-vsc.overlays.default
      ] ++ (lib.optional isLinux inputs.nur.overlays.default);
    };
  };
}
