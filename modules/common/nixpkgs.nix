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
    cudaSupport = lib.mkEnableOption "Cuda";
  };

  config = lib.mkIf config.shared.nixpkgs.enable {
    nixpkgs = {
      config = {
        allowUnfree = true;
        inherit (config.shared.nixpkgs) cudaSupport;
      };
      overlays = [ ] ++ (lib.optional isLinux inputs.nur.overlays.default);
    };
  };
}
