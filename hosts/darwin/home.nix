{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} =
      { config, ... }:
      {
        imports = [
          ../../modules/home-manager/cli
          ../../modules/home-manager/guis
          ../../modules/home-manager/terminals/bash.nix
          ../../modules/home-manager/terminals/ghostty.nix
          ../../modules/home-manager/terminals/nushell.nix
          ../../modules/home-manager/tui
          ../../modules/home-manager/config/starship.nix
          inputs.sops-nix.homeManagerModules.sops
          inputs.catppuccin.homeManagerModules.catppuccin
          {
            catppuccin = {
              enable = true;
              flavor = "frappe";
              accent = "teal";
              ghostty.enable = false;
            };
          }
          {
            home = {
              file.".warp/themes".source =
                (pkgs.callPackage ../../modules/home-manager/custom/warp-terminal-catppuccin.nix {
                  inherit (config.catppuccin) accent;
                }).outPath
                + "/share/warp/themes";
              file."Documents/catppuccin-userstyles.json".source =
                (pkgs.callPackage ../../modules/home-manager/custom/catppuccin-userstyles.nix {
                  inherit (config.catppuccin) accent flavor;
                }).outPath
                + "/dist/import.json";

              shellAliases = import ../../shared/aliases.nix {
                inherit pkgs lib;
                nixCfgPath = "${config.home.homeDirectory}/.nixpkgs/";
              };
            };
          }

          {
            hm = {
              bash.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              fzf.enable = true;
              ghostty = {
                enable = true;
                theme.flavor = config.catppuccin.flavor;
              };
              git.enable = true;
              helix.enable = true;
              nixcord = {
                enable = true;
                theme = {
                  dark = {
                    flavor = config.catppuccin.flavor;
                    accent = config.catppuccin.accent;
                  };
                  light = {
                    flavor = "latte";
                    accent = config.catppuccin.accent;
                  };
                };
              };
              nushell.enable = true;
              ssh.enable = true;
              starship.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zoxide.enable = true;
            };

            sops = {
              age.keyFile = "/Users/${username}/Library/Application Support/sops/age/keys.txt";
              defaultSopsFile = ../../secrets/secrets.yaml;
              secrets.github_ssh = { };
            };

            home.stateVersion = "24.11";
          }
        ];
      };
    extraSpecialArgs = { inherit inputs; };
  };
}
