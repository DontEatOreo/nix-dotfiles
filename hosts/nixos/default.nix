{
  inputs,
  outputs,
  nixpkgs,
  vscode-server,
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
    (
      { pkgs, ... }:
      let
        nur-no-pkgs = import nur { nurpkgs = import nixpkgs { system = "x86_64-linux"; }; };
      in
      {
        imports = [ nur-no-pkgs.repos.iopq.modules.xraya ];
        services.xraya.enable = true;
      }
    )

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

    # Remote VSCode Server
    vscode-server.nixosModules.default
    (
      { config, pkgs, ... }:
      {
        services.vscode-server.enable = true;
      }
    )

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
