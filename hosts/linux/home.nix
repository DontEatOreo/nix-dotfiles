{ inputs, pkgs, ... }:
{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };

  home-manager.users.nyx =
    { config, ... }:
    {
      imports =
        let
          modulesImports = [
            ../../modules/hm/browser
            ../../modules/hm/cli
            ../../modules/hm/gui
            ../../modules/hm/terminal
            ../../modules/hm/tui
            ../../shared/aliases.nix
            { home.stateVersion = "25.05"; }
          ];
          catppuccin = [
            inputs.catppuccin.homeModules.catppuccin
            {
              catppuccin = {
                enable = true;
                flavor = "frappe";
                accent = "blue";
                ghostty.enable = false;
              };
            }
          ];
          hm = [
            {
              hm = {
                atuin.enable = true;
                bash.enable = true;
                chromium.enable = true;
                direnv.enable = true;
                fastfetch.enable = true;
                firefox.enable = true;
                fzf.enable = true;
                ghostty.enable = true;
                git.enable = true;
                helix.enable = true;
                mpv.enable = true;
                nixcord.enable = true;
                ssh.enable = true;
                nushell.enable = true;
                starship.enable = true;
                vscode.enable = true;
                yazi.enable = true;
                zsh.enable = true;
                zoxide.enable = true;
              };
            }
          ];
        in
        modulesImports ++ catppuccin ++ hm;
    };
}
