{ pkgs, inputs, ... }:
{
  imports = [
    ../programs/linux/chromium.nix
    ../programs/linux/firefox.nix
    ../programs/linux/zshrc.nix

    ../programs/vscode

    ../programs/bashrc.nix
    ../programs/neovim.nix
    ../programs/programs.nix
    inputs.catppuccin.homeManagerModules.catppuccin
  ];
  home = {
    stateVersion = "24.05";
    packages = builtins.attrValues {
      inherit (pkgs)
        alacritty # GPU Terminal
        xclip # Clipboard for NVIM

        vesktop
        telegram-desktop
        _1password-gui
        ;
    };
  };
}
