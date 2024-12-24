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
    cudaSupport = lib.mkEnableOption "Cuda";
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
        (final: prev: {
          neovim = inputs.nixvim.packages.${system}.default;
        })
      ] ++ (lib.optional isLinux inputs.nur.overlay);
    };
  };
}
