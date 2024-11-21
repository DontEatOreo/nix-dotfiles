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
            rev = "776b160c3fa5419265342b0e0c2ec63bb8311679";
            hash = "sha256-THgGAsJr0ptZ3hu29u53X1tjSxFLe5woKYdIwewZzp8=";
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
