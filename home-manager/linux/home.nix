{pkgs, ...}: {
  imports = [
    ../programs/linux/chromium.nix
    ../programs/linux/firefox.nix
    ../programs/linux/zshrc.nix

    ../programs/vscode

    ../programs/bashrc.nix
    ../programs/direnv.nix
    ../programs/git.nix
    ../programs/neovim.nix
  ];
  home = {
    stateVersion = "24.05";
    packages = builtins.attrValues {
      inherit
        (pkgs)
        alacritty # GPU Terminal
        xclip # Clipboard for NVIM
        
        discord
        telegram-desktop
        _1password-gui
        ;
    };
  };
}
