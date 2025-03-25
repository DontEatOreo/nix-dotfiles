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
          ../../modules/hm/cli
          ../../modules/hm/guis
          ../../modules/hm/terminals/bash.nix
          ../../modules/hm/terminals/ghostty.nix
          ../../modules/hm/terminals/nushell.nix
          ../../modules/hm/tui
          ../../modules/hm/config/starship.nix
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
                (pkgs.callPackage ../../modules/hm/custom/warp-terminal-catppuccin.nix {
                  inherit (config.catppuccin) accent;
                }).outPath
                + "/share/warp/themes";
              file."Documents/catppuccin-userstyles.json".source =
                (pkgs.callPackage ../../modules/hm/custom/catppuccin-userstyles.nix {
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
              ghostty.enable = true;
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
