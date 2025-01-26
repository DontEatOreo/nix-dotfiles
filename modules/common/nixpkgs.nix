{
  inputs,
  config,
  lib,
  ...
}:
let
  inherit (config.nixpkgs.hostPlatform) isLinux;
in
{
  options.shared.nixpkgs = {
    enable = lib.mkEnableOption "Nixpkgs";
    allowUnfree = lib.mkEnableOption "Unfree Packages";
    cudaSupport = lib.mkEnableOption "Cuda";
  };

  config = lib.mkIf config.shared.nixpkgs.enable {
    nixpkgs = {
      config = { inherit (config.shared.nixpkgs) allowUnfree cudaSupport; };
      overlays = [
        inputs.catppuccin-vsc.overlays.default
      ] ++ (lib.optional isLinux inputs.nur.overlays.default);
    };
  };
}
