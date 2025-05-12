{
  lib,
  inputs,
  config,
  ...
}:
{
  imports = [ inputs.lix-module.nixosModules.default ];

  nix.settings =
    {
      experimental-features = "nix-command flakes pipe-operator";
      substituters = [
        "https://devenv.cachix.org"
        "https://nix-community.cachix.org"
        "https://helix.cachix.org"
      ];
      trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
      ];
    }
    // lib.optionalAttrs config.nixpkgs.hostPlatform.isLinux {
      flake-registry = "";
      # Workaround for https://github.com/NixOS/nix/issues/9574
      nix-path = config.nix.nixPath;
    };
  nix = {
    channel.enable = false;
    # Opinionated: make flake registry and nix path match flake inputs
    registry = lib.mapAttrs (_: flake: { inherit flake; }) (
      # Flake Inputs
      lib.filterAttrs (_: lib.isType "flake") inputs
    );
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") (
      # Flake Inputs
      lib.filterAttrs (_: lib.isType "flake") inputs
    );
  };
}
