{ lib, config, ... }:
{
  options.hm.direnv.enable = lib.mkEnableOption "Direnv";

  config = lib.mkIf config.hm.direnv.enable {
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
