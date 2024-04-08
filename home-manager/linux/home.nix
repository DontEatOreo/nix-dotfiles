{pkgs, ...}: {
  imports = [
    ../programs/neovim.nix
    ../programs/bashrc.nix
    ../programs/chromium.nix
    ../programs/firefox.nix
    ../programs/zshrc.nix
    ../programs/vscode
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
