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
      inputs.lix-module.nixosModules.default

      ./fonts.nix
      ./home.nix
      ./homebrew.nix
      ./system.nix
      ./zsh.nix

      ../../shared/cli.nix
      ../../shared/dev.nix
      ../../shared/gnuimp.nix
      ../../shared/tui.nix
      ../../shared/programs.nix
      {
        services.nix-daemon.enable = true;

        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
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
