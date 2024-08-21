{ inputs, ... }:
let
  system = "aarch64-darwin";
  username = "anon";
in
{
  "anons-Mac-mini" = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    specialArgs = {
      inherit inputs;
    };
    modules = [
      ./configuration.nix
      inputs.home-manager.darwinModules.home-manager
      {
        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
        };
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${username} = {
            imports = [ ../../home-manager/home.nix ];
          };
          extraSpecialArgs = {
            inherit inputs system;
          };
        };
      }
    ];
  };
}
