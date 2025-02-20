{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./keybindings.nix
    ./settings.nix
  ];
  options.hm.yazi.enable = lib.mkEnableOption "Yazi";

  config = lib.mkIf config.hm.yazi.enable {
    xdg.configFile = {
      "yazi/plugins/smart-paste.yazi/init.lua".text = builtins.readFile ./plugins/smart-paste.lua;
    };
    home.packages = builtins.attrValues { inherit (pkgs) mediainfo exiftool clipboard-jh; };
    programs.yazi = {
      enable = true;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "781a79846415f4946d149a11666381b21dd9e820";
            hash = "sha256-ShL+R4KSKDBsL8C9OlaxngTvljt/I2pXiDgAsSJFVqA=";
          };
        in
        {
          diff = "${pluginsRepo}/diff.yazi";
          full-border = "${pluginsRepo}/full-border.yazi";
          git = "${pluginsRepo}/git.yazi";
          hide-preview = "${pluginsRepo}/hide-preview.yazi";
          max-preview = "${pluginsRepo}/max-preview.yazi";
          smart-enter = "${pluginsRepo}/smart-enter.yazi";
          starship = pkgs.fetchFromGitHub {
            owner = "Rolv-Apneseth";
            repo = "starship.yazi";
            rev = "f6939fbdbc3fdfcdc2a80251841e429e0cd5cf3c";
            hash = "sha256-5QQsFozbulgLY/Gl6QuKSOTtygULveoRD49V00e0WOw=";
          };
          system-clipboard = pkgs.fetchFromGitHub {
            owner = "orhnk";
            repo = "system-clipboard.yazi";
            rev = "7775a80e8d3391e0b3da19ba143196960a4efc48";
            hash = "sha256-tfR9XHvRqm7yPbTu/joBDpu908oceaUoBiIImehMobk=";
          };
        };
      initLua = ''
        require('full-border'):setup()
        require("git"):setup()
        require("starship"):setup()
      '';
    };
  };
}
