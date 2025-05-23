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
      (final: prev: {
        qrencode = prev.qrencode.overrideAttrs (old: {
          src = final.fetchFromGitHub {
            owner = "fukuchi";
            repo = "libqrencode";
            rev = "v${old.version}";
            sha256 = "sha256-nbrmg9SqCqMrLE7WCfNEzMV/eS9UVCKCrjBrGMzAsLk";
          };
          nativeBuildInputs = old.nativeBuildInputs ++ [ final.autoreconfHook ];
          nativeCheckInputs = [ ];
          doCheck = false;
        });
      })
      # https://github.com/NixOS/nixpkgs/pull/391322
      (final: prev: {
        flasgger = prev.flasgger.overrideAttrs (old: {
          src = final.fetchFromGitHub {
            owner = "flasgger";
            repo = "flasgger";
            rev = "v${old.version}";
            hash = "sha256-ULEf9DJiz/S2wKlb/vjGto8VCI0QDcm0pkU5rlOwtiE=";
          };
          patches = [ ];
        });
      })
    ] ++ (lib.optional isLinux inputs.nur.overlays.default);
  };
}
