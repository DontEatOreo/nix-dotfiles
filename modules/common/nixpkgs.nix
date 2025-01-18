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
    enable = lib.mkEnableOption "Nixpkgs";
    allowUnfree = lib.mkEnableOption "Unfree Packages";
    cudaSupport = lib.mkEnableOption "Cuda";
  };

  config = lib.mkIf config.shared.nixpkgs.enable {
    nixpkgs = {
      config = { inherit (config.shared.nixpkgs) allowUnfree cudaSupport; };
      hostPlatform = system;
      overlays = [
        inputs.catppuccin-vsc.overlays.default
      ] ++ (lib.optional isLinux inputs.nur.overlays.default);
    };
  };
}
