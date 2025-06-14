{ inputs, ... }:
{
  anons-Mac-mini = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs; };
    modules = [
      ../../modules/common
      ./configuration.nix
      ./fonts.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../shared/packages.nix
    ];
  };
}
