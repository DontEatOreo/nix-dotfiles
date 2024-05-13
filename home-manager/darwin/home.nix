{ inputs, ... }:
{
  imports = [
    ../programs/vscode

    ../programs/bashrc.nix
    ../programs/neovim.nix
    ../programs/programs.nix
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  home.stateVersion = "24.05";
}
