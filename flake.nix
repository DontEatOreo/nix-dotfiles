{
  description = "My NixOS & Darwin System Flake";

  inputs = {
    catppuccin.url = "github:catppuccin/nix";

    dis.url = "github:DontEatOreo/dis";
    dis.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nixcord.url = "github:DontEatOreo/nixcord/temporary-hash-fix";
    nixcord.inputs.nixpkgs.follows = "nixpkgs";
    nixcord.inputs.flake-compat.follows = "";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixvim.url = "github:elythh/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions/0d53b7836079cda476fab76bf9becfdd475a5d1d";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.inputs.flake-compat.follows = "";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nur.url = "github:nix-community/NUR";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    xremap-flake.url = "github:xremap/nix-flake";
    xremap-flake.inputs.nixpkgs.follows = "nixpkgs";
    xremap-flake.inputs.home-manager.follows = "home-manager";
  };

  outputs = inputs: {
    darwinConfigurations = import ./hosts/darwin { inherit inputs; };
    nixosConfigurations = import ./hosts/nixos { inherit inputs; };
  };
}
