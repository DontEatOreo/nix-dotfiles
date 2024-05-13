{
  inputs,
  outputs,
  home-manager,
  ...
}:
let
  system = "aarch64-darwin";
  modules = [
    ./configuration.nix

    home-manager.darwinModules.home-manager
    {
      users.users.anon = {
        name = "anon";
        home = "/Users/anon";
      };
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.anon = import ../../home-manager/darwin/home.nix;
        extraSpecialArgs = {
          inherit inputs outputs system;
        };
      };
    }
  ];
  specialArgs = {
    inherit inputs;
  };
in
{
  "anons-Mac-mini" = inputs.nix-darwin.lib.darwinSystem {
    inherit system;
    inherit modules;
    inherit specialArgs;
  };
}
