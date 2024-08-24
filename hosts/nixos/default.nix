{ inputs, ... }:
let
  system = "x86_64-linux";
  username = "nyx";
in
{
  ${username} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit inputs system username;
    };
    modules = [
      ./configuration.nix
      ../../modules/common
      ../../modules/de

      inputs.nur.nixosModules.nur
      inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h

      # Home Manger
      inputs.home-manager.nixosModules.home-manager
      ./home.nix

      inputs.xremap-flake.nixosModules.default
    ];
  };
}
