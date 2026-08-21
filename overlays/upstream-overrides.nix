{ lib }:
final: prev:
let
  inherit (final) dotfilesSourcePins;
in
{
  # Keep the flake formatter and dev shell at the Justfile's minimum version,
  # independently of the versions in the two nixpkgs inputs.
  just =
    let
      source = dotfilesSourcePins.just;
      inherit (source) version;
      src = source.outPath;
    in
    prev.just.overrideAttrs (previousAttrs: {
      inherit src version;
      cargoDeps = final.rustPlatform.fetchCargoVendor {
        inherit src;
        hash = "sha256-zpP5XLmgQFH4+B97zMhh+iE6kS+PHTh9heH89rXCQo0=";
      };
      doCheck = false;
      doInstallCheck = false;
      meta = previousAttrs.meta // {
        changelog = "https://github.com/casey/just/blob/${version}/CHANGELOG.md";
      };
    });

  kmscon = prev.kmscon.overrideAttrs (
    _finalAttrs: previousAttrs: {
      # The pin follows upstream main rather than a release tag.
      version = "10.0.1-unstable-2026-07-31";
      src = dotfilesSourcePins.kmscon.outPath;
      buildInputs = previousAttrs.buildInputs ++ [ final.dbus ];
      mesonFlags = (previousAttrs.mesonFlags or [ ]) ++ [ "-Dtests=false" ];
      doCheck = false;
      doInstallCheck = false;
      # The pinned source installs kmscon itself as an ELF binary; only the
      # launcher script contains a command path that needs rewriting.
      postFixup = ''
        substituteInPlace $out/bin/kmscon-launch-gui \
          --replace-fail "inotifywait" "${lib.getExe' final.inotify-tools "inotifywait"}"
      '';
    }
  );
}
