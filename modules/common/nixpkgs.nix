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
  options.shared.nixpkgs.enable = lib.mkEnableOption "Enable Nixpkgs";

  config = lib.mkIf config.shared.nixpkgs.enable {
    nixpkgs = {
      config = {
        allowUnfree = true;
        cudaSupport = lib.mkIf isLinux true;
      };
      hostPlatform = system;
      overlays = (lib.optional isLinux inputs.nur.overlay);
    };
  };
}
