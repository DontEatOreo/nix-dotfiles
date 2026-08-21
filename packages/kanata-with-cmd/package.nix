{
  dotfilesSourcePins,
  kanata,
  lib,
  rustPlatform,
}:
let
  sourcePin = dotfilesSourcePins.kanata_homebrew;
  src = sourcePin.outPath;
  manifest = builtins.fromTOML (builtins.readFile (src + "/Cargo.toml"));
  version = "${manifest.package.version}-unstable-${lib.substring 0 7 sourcePin.revision}";
  patchDirectory = ./patches;
  patchNames = lib.filter (name: name != "") (
    lib.splitString "\n" (builtins.readFile (patchDirectory + /series))
  );
  patches = map (name: patchDirectory + "/${name}") patchNames;
in
(kanata.override { withCmd = true; }).overrideAttrs (previousAttrs: {
  inherit patches src version;
  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (previousAttrs) pname;
    inherit patches src version;
    hash = "sha256-QbxpUX8z1vrgVEiPTLs5ah6+qqMtZGJgbMPSYXACr10=";
  };
  doCheck = false;
  doInstallCheck = false;
})
