_: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableBashCompletion = true;
    enableFzfCompletion = true;
    enableFzfGit = true;
    enableFzfHistory = true;
    enableSyntaxHighlighting = true;
    loginShellInit = ''
      # EVAL
      eval "$(github-copilot-cli alias -- "$0")"
      eval "$(direnv hook zsh)"

      # Aliases
      ## Core Utils
      alias ls="ls --color"
      alias lt="ls --human-readable --size -1 -S --classify"
      alias ll="ls -al"
      alias ld="ls -d .*"
      alias mv="mv -iv"
      alias cp="cp -iv"
      alias rm="rm -v"
      alias mkdir="mkdir -pv"
      alias untar="tar -zxvf"
      alias grep="grep --color=auto"
      alias bc="bc -l";
      alias diff="colordiff";
      alias j="jobs -l";
      alias path="echo -e $PATH | tr ':' '\n' | nl | sort"
      alias now="date +'%T'"
      alias nowtime="now"
      alias nowdate="date +'%d-%m-%Y'"

      ## Nix
      alias update="nix flake update ~/.nixpkgs/"
      alias check="nix flake check"
      alias rebuild="darwin-rebuild switch --flake ~/.nixpkgs/"

      ## Video
      alias m4a="yt-dlp --progress --console-title --embed-thumbnail --embed-metadata --extract-audio --audio-format m4a --audio-quality 0"
      alias mp3="yt-dlp --progress --console-title --embed-thumbnail --embed-metadata --extract-audio --audio-format mp3 --audio-quality 0"
      alias mp4='yt-dlp --progress --console-title --embed-metadata -S "vcodec:h264,ext:mp4:m4a"'

      ## Dir
      alias ".."="../"
      alias ".3"="../../"
      alias ".4"="../../.."
      alias ".5"="../../../../"

      ## Misc
      alias myip="curl ipinfo.io/ip && printf '%s\n'"
    '';
  };
}
