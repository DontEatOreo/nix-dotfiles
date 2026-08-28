{ inputs, pkgs, ... }:
let
  patchedKanata = inputs.patches.packages.${pkgs.stdenv.hostPlatform.system}.kanata.overrideAttrs {
    buildFeatures = [ "cmd" ];
  };
in
{
  services.kanata = {
    enable = true;
    package = patchedKanata;
    keyboards.main = {
      configFile = builtins.path {
        path = ../../packages/kanata/kanata.kbd;
        name = "kanata-config";
      };
    };
  };
}
