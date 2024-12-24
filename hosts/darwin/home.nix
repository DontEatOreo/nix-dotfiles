{
  pkgs,
  inputs,
  username,
  system,
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
          ../../modules/home-manager/tui
          inputs.sops-nix.homeManagerModules.sops
          inputs.catppuccin.homeManagerModules.catppuccin
          {
            catppuccin = {
              enable = true;
              flavor = "frappe";
              accent = "teal";
            };
          }
          {
            home.file.".warp/themes".source =
              (pkgs.callPackage ../../modules/home-manager/custom/warp-terminal-catppuccin.nix {
                inherit (config.catppuccin) accent;
              }).outPath
              + "/share/warp/themes";
            home.file."Documents/catppuccin-userstyles.json".source =
              (pkgs.callPackage ../../modules/home-manager/custom/catppuccin-userstyles.nix {
                inherit (config.catppuccin) accent flavor;
              }).outPath
              + "/dist/import.json";
          }

          {
            hm = {
              bash.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              fzf.enable = true;
              git.enable = true;
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
              ssh.enable = true;
              vscode.enable = true;
              yazi.enable = true;
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
    extraSpecialArgs = {
      inherit inputs system;
    };
  };
}
