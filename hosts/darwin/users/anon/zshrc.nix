{pkgs, ...}: let
  yt-dlp-script = import ../../../../shared/yt-dlp-script.nix {inherit pkgs;};
in {
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

      # File Operations
      alias ls="eza --oneline"
      alias lt="eza --oneline --reverse --sort=size --size"
      alias ll="eza --long"
      alias ld="ls -d .*"
      alias mv="mv -iv"
      alias cp="cp -iv"
      alias rm="rm -v"
      alias mkdir="mkdir -pv"
      alias untar="tar -zxvf"

      # Text Processing
      alias grep="grep --color=auto"
      alias diff="colordiff"

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

      # Nix
      alias update="nix flake update ~/.nixpkgs/"
      alias check="nix flake check"
      alias rebuild="darwin-rebuild switch --use-remote-sudo --flake ~/.nixpkgs/"

      # Video
      function m4a() {
        ${yt-dlp-script} m4a "$1"
      }
      alias m4a=m4a

      function m4a-cut() {
        ${yt-dlp-script} m4a-cut "$1" "$2"
      }
      alias m4a-cut=m4a-cut

      function mp3() {
        ${yt-dlp-script} mp3 "$1"
      }
      alias mp3=mp3

      function mp3-cut() {
        ${yt-dlp-script} mp3-cut "$1" "$2"
      }
      alias mp3-cut=mp3-cut

      function mp4() {
        ${yt-dlp-script} mp4 "$1"
      }
      alias mp4=mp4

      function mp4-cut() {
        ${yt-dlp-script} mp4-cut "$1" "$2"
      }
      alias mp4-cut=mp4-cut

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
      alias micfix="sudo launchctl stop com.apple.audio.coreaudiod && sudo launchctl start com.apple.audio.coreaudiod"
    '';
  };
}
