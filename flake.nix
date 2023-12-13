{
  description = "My NixOS & Darwin System Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    flake-utils.url = "github:numtide/flake-utils";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

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
    flake-utils,
    pre-commit-hooks,
    nix-darwin,
    home-manager,
    nur,
    vscode-server,
    nix-vscode-extensions,
    ...
  } @ inputs: let
    inherit (flake-utils.lib) eachDefaultSystem;

    commonAttrs = {
      inherit (nixpkgs) lib;
      inherit (self) outputs;
      inherit nixos-hardware;
      inherit inputs self;
      inherit nixpkgs nix-darwin;
      inherit home-manager;
      inherit nur;
      inherit vscode-server;
    };

    flakeOutput =
      eachDefaultSystem
      (system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        checks = {
          pre-commit-check = pre-commit-hooks.lib.${system}.run {
            src = ./.;
            hooks.alejandra.enable = true;
          };
        };
        devShells = {
        };
        default = pkgs.mkShell {
          inherit (self.checks.${system}.pre-commit-check) shellHook;
        };
        formatter = nixpkgs.legacyPackages.${system}.alejandra;
      });
  in
    flakeOutput
    // {
      nixosConfigurations = import ./hosts/nixos commonAttrs;
      darwinConfigurations = import ./hosts/darwin commonAttrs;
    };
}
