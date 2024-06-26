_: {
  imports = [
    ./users/anon/homebrew.nix
    ./users/anon/nix.nix
    ./users/anon/nixpkgs.nix
    ./users/anon/system.nix
    ./users/anon/zshrc.nix
    ./users/anon/fonts.nix

    ../../shared/cli.nix
    ../../shared/dev.nix
    # ../../shared/latex.nix # Disabled by default due to file size
    ../../shared/tui.nix
    ../../shared/programs.nix
  ];

  services.nix-daemon.enable = true;
}
