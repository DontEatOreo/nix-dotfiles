{ lib, config, ... }:
{
  options.hm.git.enable = lib.mkEnableOption "Git";

  config = lib.mkIf config.hm.git.enable {
    programs = {
      gitui.enable = true;
      gh.enable = true;
      gh.settings.git_protocol = "ssh";
      git = {
        enable = true;
        ignores = [
          ".DS_Store"
          "Thumbs.db"
          "*.DS_Store"
          "*.swp"
        ];
        userName = "DontEatOreo";
        userEmail = "57304299+DontEatOreo@users.noreply.github.com";
        signing = {
          signByDefault = true;
          key = "0DB5361BEEE530AB";
        };
      };
    };
  };
}
