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

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixvim.url = "github:elythh/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
    let
      commonAttrs = {
        inherit (dis) dis;
        inherit (nixpkgs) lib;
        inherit inputs;
        inherit nixpkgs;
      };
    in
    {
      darwinConfigurations = import ./hosts/darwin commonAttrs;
      nixosConfigurations = import ./hosts/nixos commonAttrs;
    };
}
