{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.hm.git.enable = mkEnableOption "Enable Git";

  config = mkIf config.hm.git.enable {
    programs = {
      gitui.enable = true;
      gh.enable = true;
      git = {
        enable = true;
        delta.enable = true;
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
