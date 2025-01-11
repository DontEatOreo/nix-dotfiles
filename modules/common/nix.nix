{
  inputs,
  lib,
  config,
  system,
  ...
}:
let
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.shared.nix.enable = lib.mkEnableOption "Nix";

  config = lib.mkIf config.shared.nix.enable {
    nix =
      {
        settings =
          {
            # Enable flakes and new 'nix3' command
            experimental-features = "nix-command flakes";

            substituters = [
              "https://devenv.cachix.org"
              "https://nix-community.cachix.org"
            ];
            trusted-public-keys = [
              "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            ];
          }
          // lib.optionalAttrs isLinux {
            # Opinionated: disable global registry
            flake-registry = "";
            # Workaround for https://github.com/NixOS/nix/issues/9574
            nix-path = config.nix.nixPath;
          };
        # Opinionated: disable channels
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
      }
      // lib.optionalAttrs (!isLinux) {
        extraOptions = ''
          experimental-features = nix-command flakes
          builders-use-substitutes = true
          build-use-substitutes = true
        '';
      };
  };
}
