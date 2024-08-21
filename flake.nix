{
  description = "My NixOS & Darwin System Flake";

  inputs = {
    dis.url = "github:DontEatOreo/dis";
    dis.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixcord.url = "github:kaylorben/nixcord";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixvim.url = "github:elythh/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/03d3171c94c36f43c10c46df6fbab127af314da6";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nur.url = "github:nix-community/NUR";

    xremap-flake.url = "github:xremap/nix-flake";
    xremap-flake.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      dis,
      home-manager,
      nix-darwin,
      nix-vscode-extensions,
      nixcord,
      nixos-hardware,
      nixpkgs,
      nur,
      xremap-flake,
      ...
    }@inputs:
    {
      darwinConfigurations = import ./hosts/darwin { inherit inputs; };
      nixosConfigurations = import ./hosts/nixos { inherit inputs; };
    };
}
