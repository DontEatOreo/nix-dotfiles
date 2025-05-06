{ inputs, ... }:
let
  username = "anon";
in
{
  "anons-Mac-mini" = inputs.nix-darwin.lib.darwinSystem {
    specialArgs = { inherit inputs username; };
    modules = [
      ./fonts.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../shared/cli.nix
      ../../shared/dev.nix
      ../../shared/tui.nix
      {
        nixpkgs.hostPlatform.system = "aarch64-darwin";

        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
          shell = inputs.nixpkgs.legacyPackages.aarch64-darwin.zsh;
        };
      }

      ../../modules/common
      {
        shared = {
          nix.enable = true;
          nixpkgs.enable = true;
        };
      }
    ];
  };
}
