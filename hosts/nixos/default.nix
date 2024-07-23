{
  inputs,
  outputs,
  nixos-hardware,
  nur,
  home-manager,
  xremap-flake,
  ...
}:
let
  system = "x86_64-linux";
  specialArgs = {
    inherit inputs;
  };
  modules = [
    # > Our main NixOS configuration file <
    ./configuration.nix

    nur.nixosModules.nur

    nixos-hardware.nixosModules.lenovo-legion-15arh05h

    { nixpkgs.overlays = [ nur.overlay ]; }

    # Home Manger
    home-manager.nixosModules.home-manager
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

    xremap-flake.nixosModules.default
  ];
in
{
  nyx = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    inherit specialArgs;
    inherit modules;
  };
}
