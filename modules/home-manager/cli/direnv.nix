{ lib, config, ... }:
{
  options.hm.direnv.enable = lib.mkEnableOption "Enable Direnv";

  config = lib.mkIf config.hm.direnv.enable {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
