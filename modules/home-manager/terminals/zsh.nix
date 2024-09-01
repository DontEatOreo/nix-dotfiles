{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  yt-dlp-script = lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../../shared/scripts/yt-dlp-script.sh)
  );
  nixConfigPath = "/etc/nixos";
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.hm.zsh.enable = lib.mkEnableOption "Enable Declerative Zsh";

  config = lib.mkIf config.hm.zsh.enable {
    assertions = [
      {
        assertion = isLinux;
        message = "Declerative Zsh is only available on Linux";
      }
    ];
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting = {
        enable = true;
        highlighters = [ "brackets" ];
      };
      enableVteIntegration = true;
      autocd = true;
      initExtraFirst = ''
        eval "$(github-copilot-cli alias -- "$0")"
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
        {
          name = "fzf-tab";
          src = pkgs.zsh-fzf-tab;
        }
        {
          name = "nix-shell";
          src = pkgs.zsh-nix-shell;
        }
      ];
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "direnv"
          "sudo"
        ];
      };
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
        diff = "delta";

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
        update = "nix flake update  ${nixConfigPath}";
        check = "nix flake check  ${nixConfigPath}";
        rebuild = "nixos-rebuild switch --use-remote-sudo --flake  ${nixConfigPath}";
        test = "nixos-rebuild test --flake  ${nixConfigPath}";

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
  };
}
