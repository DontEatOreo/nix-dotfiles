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
            rev = "c5785059611624e20a37ba573620f30acc28a26a";
            hash = "sha256-wlSBtabIsEUJhuHmXwgpSnwZp9WaVQFBg6s1XXjubrE=";
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
