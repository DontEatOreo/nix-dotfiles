{
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
    users.${username} = {
      imports = [
        ../../modules/home-manager/cli
        ../../modules/home-manager/guis
        ../../modules/home-manager/terminals/bash.nix
        ../../modules/home-manager/tui
        inputs.sops-nix.homeManagerModules.sops

        {
          hm = {
            bash.enable = true;
            direnv.enable = true;
            fzf.enable = true;
            git.enable = true;
            nixcord.enable = true;
            ssh.enable = true;
            vscode.enable = true;
            yazi.enable = true;
          };

          sops = {
            age.keyFile = "/Users/${username}/Library/Application Support/sops/age/keys.txt";
            defaultSopsFile = ../../secrets/secrets.yaml;
            secrets.github_ssh = { };
          };

          home = {
            stateVersion = "24.05";
            packages = builtins.attrValues {
              nvim = inputs.nixvim.packages.${system}.default.extend {
                config.theme = inputs.nixpkgs.lib.mkForce "gruvbox";
                config.extraConfigLua = ''
                  require('btw').setup({
                    text = "I use Neovim (and macOS, BTW)",
                  })
                '';
              };
            };
          };
        }

      ];
    };
    extraSpecialArgs = {
      inherit inputs system;
    };
  };
}
