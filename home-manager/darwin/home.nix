_: {
  imports = [
    ../programs/vscode

    ../programs/bashrc.nix
    ../programs/direnv.nix
    ../programs/neovim.nix
    ../programs/git.nix
  ];

  home.stateVersion = "24.05";
}
