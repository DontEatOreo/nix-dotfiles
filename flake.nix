{
  description = "My NixOS & Darwin System Flake";

  inputs = {
    dis.url = "github:DontEatOreo/dis";
    dis.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixvim.url = "github:elythh/nixvim";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nur.url = "github:nix-community/NUR";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      dis,
      home-manager,
      nix-darwin,
      nix-vscode-extensions,
      nixos-hardware,
      nixpkgs,
      nur,
      vscode-server,
      ...
    }@inputs:
    let
      commonAttrs = {
        inherit (dis) dis;
        inherit (nixpkgs) lib;
        inherit (self) outputs;
        inherit home-manager;
        inherit inputs;
        inherit nix-darwin;
        inherit nixos-hardware;
        inherit nixpkgs;
        inherit nur;
        inherit self;
        inherit vscode-server;
      };
    in
    {
      darwinConfigurations = import ./hosts/darwin commonAttrs;
      nixosConfigurations = import ./hosts/nixos commonAttrs;
    };
}
