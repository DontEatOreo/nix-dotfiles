{ lib, config, ... }:
{
  options.hm.bash.enable = lib.mkEnableOption "Bash";

  config = lib.mkIf config.hm.bash.enable {
    programs.bash = {
      enable = true;
      enableVteIntegration = true;
      initExtra = ''
        eval "$(github-copilot-cli alias -- "$0")"
      '';
    };
  };
}
