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
    overlays = [
      (final: prev: { yt-dlp = final.callPackage ../../pkgs/yt-dlp.nix { }; })
    ] ++ (lib.optional isLinux inputs.nur.overlays.default);
  };
}
