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
      ./fonts.nix
      ./home.nix
      ./system.nix
      ./zsh.nix

      ../../shared/cli.nix
      ../../shared/dev.nix
      ../../shared/gnuimp.nix
      ../../shared/tui.nix
      ../../shared/programs.nix
      {
        users.users.${username} = {
          name = username;
          home = "/Users/${username}";
          shell = inputs.nixpkgs.legacyPackages.${system}.zsh;
        };
      }

      ../../modules/common
      {
        shared = {
          nix.enable = true;
          nixpkgs.enable = true;
          nixpkgs.allowUnfree = true;
        };
      }
    ];
  };
}
