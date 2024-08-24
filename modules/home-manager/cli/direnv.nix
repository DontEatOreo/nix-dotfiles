{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.hm.direnv.enable = mkEnableOption "Enable Direnv";

  config = mkIf config.hm.direnv.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
