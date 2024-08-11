{ pkgs, ... }:
let
  yt-dlp-script = pkgs.lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../shared/scripts/yt-dlp-script.sh)
  );
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    sessionVariables = { };
    initExtra = ''
      shopt -s autocd
      set -o vi
      eval "$(thefuck --alias)"
      eval "$(github-copilot-cli alias -- "$0")"
      export PS1="\[$(tput bold)\]\[$(tput setaf 1)\][\[$(tput setaf 3)\]\u\[$(tput setaf 2)\]@\[$(tput setaf 4)\]\h \[$(tput setaf 5)\]\W\[$(tput setaf 1)\]]\[$(tput setaf 7)\]\\$ \[$(tput sgr0)\]"
    '';
    shellAliases = {
      # File Operations
      ls = "eza --oneline";
      lt = "eza --oneline --reverse --sort=size --size";
      ll = "eza --long";
      ld = "ls -d .*";
      mv = "mv -iv";
      cp = "cp -iv";
      rm = "rm -v";
      mkdir = "mkdir -pv";
      untar = "tar -zxvf";

      # Text Processing
      grep = "grep --color=auto";
      diff = "colordiff";

      # Job Control
      j = "jobs -l";

      # Math Operations
      bc = "bc -l";

      # System Information
      path = "echo -e $PATH | tr ':' '\n' | nl | sort";

      # Date and Time
      now = "date +'%T'";
      nowtime = "now";
      nowdate = "date +'%d-%m-%Y'";

      # Editors
      vi = "nvim";
      vim = "nvim";

      # Nix
      update = "nix flake update /etc/nixos#nyx";
      check = "nix flake check";
      rebuild = "nixos-rebuild switch --use-remote-sudo --flake /etc/nixos#nyx";
      test = "nixos-rebuild test --flake /etc/nixos#nyx";

      # Video
      m4a = "${yt-dlp-script} m4a";
      m4a-cut = "${yt-dlp-script} m4a-cut";
      mp3 = "${yt-dlp-script} mp3";
      mp3-cut = "${yt-dlp-script} mp3-cut";
      mp4 = "${yt-dlp-script} mp4";
      mp4-cut = "${yt-dlp-script} mp4-cut";

      # Directory Navigation
      ".." = "../";
      ".3" = "../../";
      ".4" = "../../..";
      ".5" = "../../../../";

      # Misc
      myip = "curl ipinfo.io/ip && printf '%s\n'";
      ports = "ss -tulanp";
      xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
    };
  };
}
