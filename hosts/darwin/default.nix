{ inputs, ... }:
let
  system = "aarch64-darwin";
  username = "anon";
in
{
  "anons-Mac-mini" = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      inherit inputs system username;
    };
    modules = [
      ./configuration.nix
      ../../modules/common
      inputs.home-manager.darwinModules.home-manager
      inputs.lix-module.nixosModules.default
      ./home.nix
      {
        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
        };
      }
    ];
  };
}
