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
        inputs.catppuccin.homeManagerModules.catppuccin
        {
          catppuccin = {
            enable = true;
            flavor = "frappe";
            accent = "blue";
          };
        }

        {
          hm = {
            bash.enable = true;
            direnv.enable = true;
            fastfetch.enable = true;
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
            packages = [ inputs.nixvim.packages.${system}.default ];
          };
        }
      ];
    };
    extraSpecialArgs = {
      inherit inputs system;
    };
  };
}
