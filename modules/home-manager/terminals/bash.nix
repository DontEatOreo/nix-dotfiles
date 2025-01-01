{ lib, config, ... }:
{
  options.hm.bash.enable = lib.mkEnableOption "Bash";

  config = lib.mkIf config.hm.bash.enable {
    programs.bash = {
      enable = true;
      enableCompletion = true;
      initExtra = ''
        shopt -s autocd
        set -o vi
        eval "$(github-copilot-cli alias -- "$0")"
        export PS1="\[$(tput bold)\]\[$(tput setaf 1)\][\[$(tput setaf 3)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 4)\]\h \[$(tput setaf 5)\]\W\[$(tput setaf 1)\]]\[$(tput setaf 7)\]\\$ \[$(tput sgr0)\]"
      '';
    };
  };
}
