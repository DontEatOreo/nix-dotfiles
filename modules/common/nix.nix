{
  inputs,
  lib,
  config,
  system,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  enableOnSystem = x: y: (mkIf (system == x) y);
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.shared.nix.enable = mkEnableOption "Enable Nix";

  config = mkIf config.shared.nix.enable {
    nix = {
      settings = {
        # Enable flakes and new 'nix3' command
        experimental-features = "nix-command flakes";
        # Opinionated: disable global registry
        flake-registry = enableOnSystem isLinux "";
        # Workaround for https://github.com/NixOS/nix/issues/9574
        nix-path = enableOnSystem isLinux config.nix.nixPath;

        auto-optimise-store = true;
        substituters = [
          "https://devenv.cachix.org"
          "https://nix-community.cachix.org"
          "https://cuda-maintainers.cachix.org"
        ];
        trusted-public-keys = [
          "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
        ];
      };
      # Opinionated: disable channels
      channel.enable = false;

      extraOptions = enableOnSystem "aarch64-darwin" ''
        experimental-features = nix-command flakes
        builders-use-substitutes = true
        build-use-substitutes = true
      '';

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
  };

}
