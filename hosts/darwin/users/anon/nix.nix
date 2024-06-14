{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  nix = {
    package = pkgs.nix;

    # Add each flake input as a registery, to make nix3 commands consistent with flake.nix
    registry = (lib.mapAttrs (_: flake: { inherit flake; })) (
      (lib.filterAttrs (_: lib.isType "flake")) inputs
    );

    # Garbage Collection
    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
    # auto-optimise-store = true
    extraOptions = ''
      experimental-features = nix-command flakes
      builders-use-substitutes = true
      build-use-substitutes = true
    '';
    settings = {
      # NOTE: Disabled until 4119 is fixed...
      # sandbox = true;
      trusted-users = [
        "root"
        "nyx"
        "anon"
      ];
      # Trust Devenv Shell
      trusted-substituters = [ "https://devenv.cachix.org" ];
      trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
    };

    distributedBuilds = true;
    buildMachines = [ ];
  };
}
