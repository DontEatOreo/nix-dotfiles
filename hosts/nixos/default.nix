{ inputs, outputs, ... }:
let
  system = "x86_64-linux";
in
{
  nyx = inputs.nixpkgs.lib.nixosSystem {
    specialArgs = {
      inherit inputs;
    };
    modules = [
      # > Our main NixOS configuration file <
      ./configuration.nix

      inputs.nur.nixosModules.nur

      inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h

      { nixpkgs.overlays = [ inputs.nur.overlay ]; }

      # Home Manger
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.nyx = import ../../home-manager/home.nix;
          backupFileExtension = "backup";
          extraSpecialArgs = {
            inherit inputs outputs system;
          };
        };
      }

      inputs.xremap-flake.nixosModules.default
    ];
  };
}
