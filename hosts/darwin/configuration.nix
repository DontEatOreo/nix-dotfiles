_: {
  imports = [
    ./homebrew.nix
    ./nix.nix
    ./nixpkgs.nix
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

  services.nix-daemon.enable = true;
}
