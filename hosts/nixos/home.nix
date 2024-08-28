{
  inputs,
  system,
  username,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = {
      imports = [
        ../../modules/home-manager/browsers
        ../../modules/home-manager/cli
        ../../modules/home-manager/config/dconf.nix
        ../../modules/home-manager/guis
        ../../modules/home-manager/terminals
        ../../modules/home-manager/tui
        inputs.nixcord.homeManagerModules.nixcord

        {
          hm = {
            bash.enable = true;
            chromium.enable = true;
            dconf.enable = true;
            direnv.enable = true;
            firefox.enable = true;
            fzf.enable = true;
            git.enable = true;
            nixcord.enable = true;
            vscode.enable = true;
            yazi.enable = true;
            zsh.enable = true;
          };

          home = {
            stateVersion = "24.05";
            packages = builtins.attrValues {
              nvim = inputs.nixvim.packages.${system}.default.extend {
                config.theme = inputs.nixpkgs.lib.mkForce "gruvbox";
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
