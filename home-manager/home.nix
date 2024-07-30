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
    ./programs/linux/dconf.nix
    ./programs/linux/firefox.nix
    ./programs/linux/zshrc.nix
  ];

  linuxHome = {
    stateVersion = "24.05";
    packages = builtins.attrValues {
      nvim = inputs.nixvim.packages.${pkgs.system}.default.extend {
        config.theme = pkgs.lib.mkForce "gruvbox";
      };
      # This is how Discordia was meant to be used, a TRUE Discordian setup...
      vesktop = pkgs.vesktop.override {
        withSystemVencord = true;
        withMiddleClickScroll = true;
        withTTS = false;
      };
    };
  };

  darwinHome = {
    stateVersion = "24.05";
    packages = builtins.attrValues {
      nvim = inputs.nixvim.packages.${pkgs.system}.default.extend {
        config.theme = pkgs.lib.mkForce "gruvbox";
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
