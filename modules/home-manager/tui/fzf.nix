{ lib, config, ... }:
{
  options.hm.fzf.enable = lib.mkEnableOption "FZF";

  config = lib.mkIf config.hm.fzf.enable {
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
