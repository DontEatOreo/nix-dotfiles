{ inputs, ... }: {
  imports = [
    ../programs/vscode

    ../programs/bashrc.nix
    ../programs/direnv.nix
    ../programs/neovim.nix
    ../programs/git.nix
    ../programs/gitui.nix
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  home.stateVersion = "24.05";
}
