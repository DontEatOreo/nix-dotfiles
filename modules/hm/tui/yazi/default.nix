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
      "yazi/plugins/smart-paste.yazi/main.lua".text = builtins.readFile ./plugins/smart-paste.lua;
    };
    home.packages = builtins.attrValues { inherit (pkgs) mediainfo exiftool clipboard-jh; };
    programs.yazi = {
      enable = true;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "a1738e8088366ba73b33da5f45010796fb33221e";
            hash = "sha256-eiLkIWviGzG9R0XP1Cik3Bg0s6lgk3nibN6bZvo8e9o=";
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
            rev = "c0707544f1d526f704dab2da15f379ec90d613c2";
            hash = "sha256-H8j+9jcdcpPFXVO/XQZL3zq1l5f/WiOm4YUxAMduSRs=";
          };
          system-clipboard = pkgs.fetchFromGitHub {
            owner = "orhnk";
            repo = "system-clipboard.yazi";
            rev = "efb8f03e632adcdc6677fd5f471c74f4c71fdf9a";
            hash = "sha256-zOQQvbkXq71t2E4x45oM4MzVRlZ4hhe6RkvgcP8tdYE=";
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
