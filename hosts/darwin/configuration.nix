_: {
  imports = [
    ./homebrew.nix
    ./system.nix
    ./zshrc.nix
    ./fonts.nix

    ../../shared/cli.nix
    ../../shared/dev.nix
    ../../shared/gnuimp.nix
    # ../../shared/latex.nix # Disabled by default due to file size
    ../../shared/tui.nix
    ../../shared/programs.nix
  ];

  shared = {
    nix.enable = true;
    nixpkgs.enable = true;
  };

  services.nix-daemon.enable = true;
}
