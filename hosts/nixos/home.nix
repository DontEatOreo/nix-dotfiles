{
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} =
      { config, ... }:
      {
        imports = [
          ../../modules/home-manager/browsers
          ../../modules/home-manager/cli
          ../../modules/home-manager/config/dconf.nix
          ../../modules/home-manager/guis
          ../../modules/home-manager/terminals
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
            home.shellAliases = import ../../shared/aliases.nix {
              inherit pkgs lib;
              nixCfgPath = "/etc/nixos";
            };
          }
          {
            hm = {
              bash.enable = true;
              chromium.enable = true;
              dconf.enable = true;
              direnv.enable = true;
              fastfetch.enable = true;
              firefox.enable = true;
              fzf.enable = true;
              ghostty.enable = true;
              git.enable = true;
              helix.enable = true;
              mpv.enable = true;
              nixcord = {
                enable = true;
                theme = {
                  dark = {
                    inherit (config.catppuccin) flavor accent;
                  };
                  light = {
                    flavor = "latte";
                    inherit (config.catppuccin) accent;
                  };
                };
              };
              ssh.enable = true;
              nushell.enable = true;
              starship.enable = true;
              vscode.enable = true;
              yazi.enable = true;
              zsh.enable = true;
              zoxide.enable = true;
            };

            sops = {
              age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
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
