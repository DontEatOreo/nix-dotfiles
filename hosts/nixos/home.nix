{
  pkgs,
  inputs,
  system,
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
          inputs.xremap-flake.homeManagerModules.default
          {
            catppuccin = {
              enable = true;
              flavor = "frappe";
              accent = "teal";
            };
            home.shellAliases = import ../../shared/aliases.nix {
              inherit (pkgs) writeScriptBin;
              inherit (pkgs.lib) getExe;
              inherit system;
              nixConfigPath = "/etc/nixos";
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
              ghostty = {
                enable = true;
                theme.flavor = config.catppuccin.flavor;
              };
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
          {
            services.xremap.withGnome = true;
            services.xremap.config.keymap = [
              {
                name = "Swap CapsLock and Escape Keys";
                remap = {
                  "CapsLock" = "Esc";
                  "Esc" = "CapsLock";
                };
              }
              {
                name = "Ctrl+Arrows for Start/End of Line";
                remap = {
                  "Ctrl-Left" = "Home";
                  "Ctrl-Right" = "End";
                };
              }
              {
                name = "Alt+Arrows for Jumping Between Words";
                remap = {
                  "Alt-Left" = "Ctrl-Left";
                  "Alt-Right" = "Ctrl-Right";
                };
              }
              {
                name = "Ctrl+Up/Down for Start/End of Page";
                remap = {
                  "Ctrl-Up" = "Ctrl-Home";
                  "Ctrl-Down" = "Ctrl-End";
                };
              }
              {
                name = "Restore original key behavior in Ghostty";
                application.only = [ "ghostty" ];
                remap = {
                  "Alt-Left" = "Alt-Left";
                  "Alt-Right" = "Alt-Right";
                  "Ctrl-Left" = "Ctrl-Left";
                  "Ctrl-Right" = "Ctrl-Right";
                };
              }
            ];
          }
        ];
      };
    extraSpecialArgs = {
      inherit inputs system;
    };
  };
}
