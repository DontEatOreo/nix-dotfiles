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
  options.hm.yazi.enable = lib.mkEnableOption "Enable Yazi";

  config = lib.mkIf config.hm.yazi.enable {
    xdg.configFile = {
      "yazi/plugins/smart-paste.yazi/init.lua".text = builtins.readFile ./plugins/smart-paste.lua;
      "yazi/plugins/smart-enter.yazi/init.lua".text = builtins.readFile ./plugins/smart-enter.lua;
    };
    home.packages = builtins.attrValues { inherit (pkgs) mediainfo exiftool; };
    programs.yazi = {
      enable = true;
      plugins =
        let
          pluginsRepo = pkgs.fetchFromGitHub {
            owner = "yazi-rs";
            repo = "plugins";
            rev = "ec97f8847feeb0307d240e7dc0f11d2d41ebd99d";
            hash = "sha256-By8XuqVJvS841u+8Dfm6R8GqRAs0mO2WapK6r2g7WI8=";
          };
        in
        {
          diff = "${pluginsRepo}/diff.yazi";
          full-border = "${pluginsRepo}/full-border.yazi";
          git = "${pluginsRepo}/git.yazi";
          hide-preview = "${pluginsRepo}/hide-preview.yazi";
          max-preview = "${pluginsRepo}/max-preview.yazi";
        };
      initLua = ''
        require('full-border'):setup()
        require("git"):setup()
      '';
    };
  };
}
