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
      inputs.nur.overlays.default
      (final: prev: {
        yt-dlp = final.callPackage ../../pkgs/yt-dlp.nix { };
        yt-dlp-script = final.callPackage ../../pkgs/yt-dlp-script.nix { };
      })
      (final: prev: {
        lix =
          (inputs.lix.packages.${config.nixpkgs.hostPlatform.system}.default.override { aws-sdk-cpp = null; })
          .overrideAttrs
            (args: {
              postPatch =
                (args.postPatch or "")
                + ''
                  substituteInPlace lix/libmain/shared.cc \
                    --replace-fail "(Lix, like Nix)" "(Lix, like Nix but better)"        
                '';
              # This assumes that the tests will never break
              doCheck = false;
            });
      })
    ];
  };
}
