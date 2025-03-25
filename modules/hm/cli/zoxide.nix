{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.hm.zoxide.enable = lib.mkEnableOption "Zoxide";

  config = lib.mkIf config.hm.zoxide.enable {
    programs.zoxide.enable = true;
  };
}
