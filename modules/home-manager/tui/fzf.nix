{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.hm.fzf.enable = mkEnableOption "Enable FZF";

  config = mkIf config.hm.fzf.enable {
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
