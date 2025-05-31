{ pkgs, inputs, ... }:
{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.anon =
      { config, ... }:
      {
        imports = [
          ../../modules/hm/cli
          ../../modules/hm/gui
          ../../modules/hm/terminal/bash.nix
          ../../modules/hm/terminal/ghostty.nix
          ../../modules/hm/terminal/nushell.nix
          ../../modules/hm/tui
          ../../modules/hm/config/starship.nix
          ../../shared/aliases.nix
          inputs.catppuccin.homeModules.catppuccin
          {
            catppuccin = {
              enable = true;
              flavor = "frappe";
              accent = "blue";
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
                (pkgs.callPackage ../../pkgs/warp-terminal-catppuccin.nix {
                  inherit (config.catppuccin) accent;
                }).outPath
                + "/share/warp/themes";
              file."Documents/catppuccin-userstyles.json".source =
                (pkgs.callPackage ../../pkgs/catppuccin-userstyles.nix {
                  inherit (config.catppuccin) accent flavor;
                }).outPath
                + "/dist/import.json";
            };
          }
          {
            hm = {
              atuin.enable = true;
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
            home.stateVersion = "25.05";
          }
        ];
      };
    extraSpecialArgs = { inherit inputs; };
  };
}
