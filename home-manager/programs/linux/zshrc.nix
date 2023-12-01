{
  config,
  pkgs,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    enableVteIntegration = true;
    autocd = true;
    initExtraFirst = ''
      eval "$(github-copilot-cli alias -- "$0")"
      eval "$(direnv hook zsh)"
    '';
    plugins = [
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
      }
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = ../config;
        file = "p10k.zsh";
      }
    ];
    oh-my-zsh = {
      enable = true;
      plugins = ["git" "thefuck" "direnv" "sudo"];
    };
    shellAliases = {
      # Core Utils
      ls = "ls --color";
      lt = "ls --human-readable --size -1 -S --classify";
      ll = "ls -al";
      ld = "ls -d .*";
      mv = "mv -iv";
      cp = "cp -iv";
      rm = "rm -v";
      mkdir = "mkdir -pv";
      untar = "tar -zxvf";
      grep = "grep --color=auto";
      bc = "bc -l";
      diff = "colordiff";
      j = "jobs -l";
      path = "echo -e $PATH | tr ':' '\n' | nl | sort";
      now = "date +'%T'";
      nowtime = "now";
      nowdate = "date +'%d-%m-%Y'";

      # Nix
      update = "nix flake update /etc/nixos#nyx";
      check = "nix flake check";
      rebuild = "nixos-rebuild switch --use-remote-sudo --flake /etc/nixos#nyx";
      test = "nixos-rebuild test --flake /etc/nixos#nyx";

      # Video
      m4a = "yt-dlp --progress --console-title --embed-thumbnail --embed-metadata --extract-audio --audio-format m4a --audio-quality 0";
      mp3 = "yt-dlp --progress --console-title --embed-thumbnail --embed-metadata --extract-audio --audio-format mp3 --audio-quality 0";
      mp4 = "yt-dlp --progress --console-title --embed-metadata -S \"vcodec:h264,ext:mp4:m4a\"";

      # Dir
      ".." = "../";
      ".3" = "../../";
      ".4" = "../../..";
      ".5" = "../../../../";

      # Misc
      myip = "curl ipinfo.io/ip && printf '%s\n'";
      ports = "ss -tulanp";
      xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
    };
    history = {
      size = 10000;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreSpace = true;
      share = true;
      path = "${config.xdg.dataHome}/zsh/history";
    };
  };
}
