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
      { config, osConfig, ... }:
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
          inputs.catppuccin.homeModules.catppuccin
          {
            catppuccin = {
              enable = true;
              flavor = "frappe";
              accent = "teal";
              ghostty.enable = false;
            };
          }
          {
            services.macos-remap-keys.enable = true;
            services.macos-remap-keys.keyboard = {
              Capslock = "Escape";
              Escape = "Capslock";
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
            };
          }
          {
            programs.bash.shellAliases =
              (pkgs.callPackage ../../shared/aliases.nix { inherit osConfig; }).aliases;
            programs.zsh.shellAliases =
              (pkgs.callPackage ../../shared/aliases.nix { inherit osConfig; }).aliases;
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
