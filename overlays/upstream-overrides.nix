{ lib }:
final: prev:
let
  inherit (final) dotfilesSourcePins;
in
{
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
