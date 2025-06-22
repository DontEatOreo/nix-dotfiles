{
  description = "My NixOS & Darwin System Flake";

  inputs = {
    catppuccin.inputs.nixpkgs.follows = "nixpkgs";
    catppuccin.url = "github:catppuccin/nix";

    dis.inputs.nixpkgs.follows = "nixpkgs";
    dis.url = "github:DontEatOreo/dis/develop";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";

    helix-editor.inputs.nixpkgs.follows = "nixpkgs";
    helix-editor.inputs.rust-overlay.follows = "rust-overlay";
    helix-editor.url = "github:helix-editor/helix";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-25.05";

    jj-vcs.inputs.flake-utils.follows = "flake-utils";
    jj-vcs.inputs.nixpkgs.follows = "nixpkgs";
    jj-vcs.inputs.rust-overlay.follows = "rust-overlay";
    jj-vcs.url = "github:jj-vcs/jj";

    lix-module.inputs.flake-utils.follows = "flake-utils";
    lix-module.inputs.nixpkgs.follows = "nixpkgs";
    lix-module.url = "git+https://git.lix.systems/lix-project/nixos-module?ref=2.93.0";

    lix.inputs.flake-compat.follows = "";
    lix.inputs.nix2container.follows = "";
    lix.inputs.nixpkgs.follows = "nixpkgs";
    lix.inputs.pre-commit-hooks.follows = "";
    lix.url = "https://git.lix.systems/lix-project/lix/archive/2.93.0.tar.gz";

    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";

    nix-vscode-extensions.inputs.flake-utils.follows = "flake-utils";
    nix-vscode-extensions.inputs.nixpkgs.follows = "nixpkgs";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    nixcord.inputs.flake-compat.follows = "flake-compat";
    nixcord.inputs.flake-parts.follows = "flake-parts";
    nixcord.inputs.nixpkgs.follows = "nixpkgs";
    nixcord.url = "github:KaylorBen/nixcord";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05-small";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    nur.inputs.flake-parts.follows = "flake-parts";
    nur.inputs.nixpkgs.follows = "nixpkgs";
    nur.inputs.treefmt-nix.follows = "treefmt-nix";
    nur.url = "github:nix-community/NUR";

    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    rust-overlay.url = "github:oxalica/rust-overlay";

    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";

    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs: {
    darwinConfigurations = import ./hosts/darwin { inherit inputs; };
    nixosConfigurations = import ./hosts/linux { inherit inputs; };
  };
}
