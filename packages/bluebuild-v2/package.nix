{
  dotfilesSourcePins,
  lib,
  rustPlatform,
}:
let
  sourcePin = dotfilesSourcePins.bluebuild-cli;
  src = sourcePin.outPath;
  manifest = builtins.fromTOML (builtins.readFile (src + "/Cargo.toml"));
  version = "${manifest.workspace.package.version}-unstable-${lib.substring 0 8 sourcePin.revision}";
in
rustPlatform.buildRustPackage {
  pname = "bluebuild";
  inherit version src;

  # Upstream updated Cargo.lock to git2 0.21.0 without updating this optional
  # build dependency, leaving offline/vendored builds unable to resolve it.
  postPatch = ''
    if grep --quiet --fixed-strings 'git2 = { version = "=0.20.0"' Cargo.toml; then
      substituteInPlace Cargo.toml \
        --replace-fail 'git2 = { version = "=0.20.0"' 'git2 = { version = "=0.21.0"'
    fi
  '';

  cargoLock.lockFile = "${src}/Cargo.lock";
  buildFeatures = [ "recipe-v2" ];
  doCheck = false;
  doInstallCheck = false;

  meta = {
    description = "BlueBuild CLI with the feature-gated recipe v2 parser";
    homepage = "https://github.com/blue-build/cli";
    license = lib.licenses.asl20;
    mainProgram = "bluebuild";
    platforms = lib.platforms.linux;
  };
}
