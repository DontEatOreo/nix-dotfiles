{
  inputs,
  pkgs,
  system,
  ...
}:
let
  crossPlatformImports = [
    ./programs/vscode
    ./programs/bashrc.nix
    ./programs/programs.nix
  ];

  linuxImports = [
    ./programs/linux/chromium.nix
    ./programs/linux/firefox.nix
    ./programs/linux/zshrc.nix
  ];

  linuxHome = {
    stateVersion = "24.05";
    packages = builtins.attrValues {
      nvim = inputs.nixvim.packages.${pkgs.system}.default.nixvimExtend {
        config.theme = pkgs.lib.mkForce "decay";
      };
      inherit (pkgs)
        alacritty # GPU Terminal
        xclip # Clipboard for NVIM
        vesktop # A modded Discordian Client (Not having a modded client is like being below middle class...)
        telegram-desktop
        _1password-gui
        ;
    };
  };

  darwinHome = {
    stateVersion = "24.05";
    packages = builtins.attrValues {
      nvim = inputs.nixvim.packages.${pkgs.system}.default.nixvimExtend {
        config.theme = pkgs.lib.mkForce "decay";
        config.extraConfigLua = ''
          require('btw').setup({
            text = "I use Neovim (and macOS, BTW)",
          })
        '';
      };
    };
  };

  isLinux = builtins.elem system [
    "x86_64-linux"
    "aarch64-linux"
  ];
in
{
  imports =
    if isLinux then
      builtins.concatLists [
        crossPlatformImports
        linuxImports
      ]
    else
      crossPlatformImports;
  home = if isLinux then linuxHome else darwinHome;
}
