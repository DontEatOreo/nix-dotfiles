{ pkgs, ... }:
let
  yt-dlp-script = pkgs.lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../shared/scripts/yt-dlp-script.sh)
  );
  nixConfigPath = "~/.nixpkgs";
in
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableFzfCompletion = true;
    enableFzfGit = true;
    enableFzfHistory = true;
    enableSyntaxHighlighting = true;
    loginShellInit = ''
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh

      source ${../../modules/home-manager/config/p10k.zsh}
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme

      eval "$(github-copilot-cli alias -- "$0")"

      # File Operations
      alias ls="eza --oneline"
      alias lt="eza --oneline --reverse --sort=size"
      alias ll="eza --long"
      alias ld="ls -d .*"
      alias mv="mv -iv"
      alias cp="cp -iv"
      alias rm="rm -v"
      alias mkdir="mkdir -pv"
      alias untar="tar -zxvf"

      # Text Processing
      alias grep="grep --color=auto"
      alias diff="delta"

      # Job Control
      alias j="jobs -l"

      # Math Operations
      alias bc="bc -l"

      # System Information
      alias path="echo -e $PATH | tr ':' '\n' | nl | sort"

      # Date and Time
      alias now="date +'%T'"
      alias nowtime="now"
      alias nowdate="date +'%d-%m-%Y'"

      # Editors
      alias vi="nvim";
      alias vim="nvim";

      # Nix
      alias update="nix flake update ${nixConfigPath}"
      alias check="nix flake check ${nixConfigPath}"
      alias rebuild="darwin-rebuild switch --flake ${nixConfigPath}"

      # Video
      alias m4a="${yt-dlp-script} m4a"
      alias m4a-cut="${yt-dlp-script} m4a-cut"
      alias mp3="${yt-dlp-script} mp3"
      alias mp3-cut="${yt-dlp-script} mp3"
      alias mp4="${yt-dlp-script} mp4"
      alias mp4-cut="${yt-dlp-script} mp4-cut"

      # Directory Navigation
      alias ".."="../"
      alias ".3"="../../"
      alias ".4"="../../.."
      alias ".5"="../../../../"

      # Misc
      alias myip="curl ipinfo.io/ip && printf '%s\n'"
      alias ports="ss -tulanp"
      alias xdg-data-dirs="echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort"
      # Fix for my headphones
      alias micfix="sudo killall coreaudiod"
    '';
  };
}
