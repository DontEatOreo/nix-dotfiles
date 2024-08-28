{
  inputs,
  username,
  system,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../../modules/home-manager/cli
        ../../modules/home-manager/guis
        ../../modules/home-manager/terminals/bash.nix
        ../../modules/home-manager/tui
        inputs.nixcord.homeManagerModules.nixcord

        {
          hm = {
            bash.enable = true;
            direnv.enable = true;
            fzf.enable = true;
            git.enable = true;
            nixcord.enable = true;
            vscode.enable = true;
            yazi.enable = true;
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
