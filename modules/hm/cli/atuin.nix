{ lib, config, ... }:
{
  options.hm.atuin.enable = lib.mkEnableOption "Atuin";

  config = lib.mkIf config.hm.atuin.enable {
    programs.atuin = {
      enable = true;
      daemon.enable = true;
      flags = [ "--disable-up-arrow" ];
    };
  };
}
