{
  pkgs,
  lib,
  config,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  imports = [
    ./keybindings.nix
    ./settings.nix
  ];
  options.hm.yazi.enable = mkEnableOption "Enable Yazi";

  config = mkIf config.hm.yazi.enable {
    xdg.configFile = {
      "yazi/plugins/smart-paste.yazi/init.lua".text = builtins.readFile ./plugins/smart-paste.lua;
      "yazi/plugins/smart-enter.yazi/init.lua".text = builtins.readFile ./plugins/smart-enter.lua;
    };
    home.packages = builtins.attrValues { inherit (pkgs) mediainfo exiftool; };
    programs.yazi = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "b6597919540731691158831bf1ff36ed38c1964e";
            hash = "sha256-clyhjvIhhSaWDLGDE+dA8+lxE3fZwo9GI1pVRDQ4tR0=";
          };
        in
        {
          full-border = "${pluginsRepo}/full-border.yazi";
          max-preview = "${pluginsRepo}/max-preview.yazi";
          hide-preview = "${pluginsRepo}/hide-preview.yazi";
          diff = "${pluginsRepo}/diff.yazi";
        };
      initLua = "require('full-border'):setup()";
    };
  };
}
