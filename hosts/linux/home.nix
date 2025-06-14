{ inputs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.nyx =
      { config, ... }:
      {
        imports = [
          ../../modules/hm/browser
          ../../modules/hm/cli
          ../../modules/hm/config/dconf.nix
          ../../modules/hm/gui
          ../../modules/hm/terminal
          ../../modules/hm/tui
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
            hm = {
              atuin.enable = true;
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
            home.stateVersion = "25.05";
          }
        ];
      };
    extraSpecialArgs = { inherit inputs; };
  };
}
