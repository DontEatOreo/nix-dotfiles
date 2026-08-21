{ inputs, lib }:
_final: prev:
let
  unstable = import inputs.nixpkgs-unstable {
    localSystem = prev.stdenv.hostPlatform;
    inherit (prev) config;
  };

  # Give eupkgs its own recursive callPackage scope on top of unstable. This
  # lets eupkgs packages see one another without adding the entire overlay to
  # the top-level package set or recomputing the nixpkgs fixed point.
  eupkgsScope = lib.makeScope unstable.newScope (
    scopeFinal: inputs.eupkgs.overlays.default scopeFinal unstable
  );
  eupkgs = removeAttrs eupkgsScope [
    "_internalCallByNamePackageFile"
    "callPackage"
    "newScope"
    "overrideScope"
    "packages"
  ];
in
{
  inherit eupkgs unstable;
}
