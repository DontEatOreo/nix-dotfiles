{ inputs, ... }:
{
  anons-Mac-mini = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = {
      inherit inputs;
      pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.aarch64-darwin;
    };
    modules = [
      ../../modules/common
      ./configuration.nix
      ./fonts.nix
      ./home.nix
      ./system.nix

      ../../shared/packages.nix
    ];
  };
}
