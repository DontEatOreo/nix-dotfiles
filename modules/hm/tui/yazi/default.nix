{
  inputs,
  pkgs,
  lib,
  config,
  osConfig,
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
      package = inputs.yazi.packages.${osConfig.nixpkgs.hostPlatform.system}.default.overrideAttrs ({
        doCheck = false;
      });
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "b8860253fc44e500edeb7a09db648a829084facd";
            hash = "sha256-29K8PmBoqAMcQhDIfOVnbJt2FU4BR6k23Es9CqyEloo=";
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
            rev = "a63550b2f91f0553cc545fd8081a03810bc41bc0";
            hash = "sha256-PYeR6fiWDbUMpJbTFSkM57FzmCbsB4W4IXXe25wLncg=";
          };
          system-clipboard = pkgs.applyPatches {
            src = pkgs.fetchFromGitHub {
              owner = "orhnk";
              repo = "system-clipboard.yazi";
              rev = "efb8f03e632adcdc6677fd5f471c74f4c71fdf9a";
              hash = "sha256-zOQQvbkXq71t2E4x45oM4MzVRlZ4hhe6RkvgcP8tdYE=";
            };
            patches = [
              (pkgs.fetchpatch {
                url = "https://patch-diff.githubusercontent.com/raw/orhnk/system-clipboard.yazi/pull/8.diff";
                hash = "sha256-ry69NDWbrQ7dHP5N2CVPEcxe7LEFNQ4Ojgmso2NptJ8=";
              })
            ];
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
