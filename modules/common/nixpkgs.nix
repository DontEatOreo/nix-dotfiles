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
  nixpkgs = {
    config = {
      allowUnfree = true;
    } // lib.optionalAttrs isLinux { nixpkgs.config.cudaSupport = true; };
    overlays = [ ] ++ (lib.optional isLinux inputs.nur.overlays.default);
  };
}
