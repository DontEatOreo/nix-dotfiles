{
  description = "My NixOS & Darwin System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    dis.url = "github:DontEatOreo/dis";
    dis.inputs.nixpkgs.follows = "nixpkgs";

    # Firefox Extensions
    nur.url = "github:nix-community/NUR";

    vscode-server.url = "github:nix-community/nixos-vscode-server";
    vscode-server.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    pre-commit-hooks,
    nix-darwin,
    home-manager,
    dis,
    nur,
    vscode-server,
    nix-vscode-extensions,
    ...
  } @ inputs: let
    commonAttrs = {
      inherit (nixpkgs) lib;
      inherit (self) outputs;
      inherit (dis) dis;
      inherit nixos-hardware;
      inherit inputs self;
      inherit nixpkgs nix-darwin;
      inherit home-manager;
      inherit nur;
      inherit vscode-server;
    };
  in {
    nixosConfigurations = import ./hosts/nixos commonAttrs;
    darwinConfigurations = import ./hosts/darwin commonAttrs;
  };
}
