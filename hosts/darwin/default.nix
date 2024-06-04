{
  inputs,
  outputs,
  home-manager,
  ...
}:
let
  system = "aarch64-darwin";
  username = "anon";
  modules = [
    ./configuration.nix

    home-manager.darwinModules.home-manager
    {
      users.users.${username} = {
        name = username;
        home = "/Users/${username}";
      };
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users.${username} = import ../../home-manager/home.nix;
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
