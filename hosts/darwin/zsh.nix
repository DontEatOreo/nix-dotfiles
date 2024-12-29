{
  pkgs,
  lib,
  config,
  username,
  ...
}:
let
  yt-dlp-script = lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../../shared/scripts/yt-dlp-script.sh)
  );
  nixConfigPath = "${config.users.users.${username}.home}/.nixpkgs";

  mkAlias = name: value: "alias ${name}=\"${value}\"";

  programAliases = {
    htop = "btop";
    neofetch = "fastfetch";
  };

  fileOpAliases = {
    ls = "eza --oneline";
    lt = "eza --oneline --reverse --sort=size";
    ll = "eza --long";
    ld = "ls -d .*";
    mv = "mv -iv";
    cp = "cp -iv";
    rm = "rm -v";
    mkdir = "mkdir -pv";
    untar = "tar -zxvf";
  };

  textProcAliases = {
    grep = "grep --color=auto";
    diff = "delta";
  };

  systemAliases = {
    j = "jobs -l";
    path = "echo -e $PATH | tr ':' '\n' | nl | sort";
    myip = "curl ipinfo.io/ip && printf '%s\n'";
    ports = "ss -tulanp";
    "xdg-data-dirs" = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
    micfix = "sudo killall coreaudiod";
  };

  timeAliases = {
    now = "date +'%T'";
    nowtime = "now";
    nowdate = "date +'%d-%m-%Y'";
  };

  editorAliases = {
    vi = "nvim";
    vim = "nvim";
  };

  nixAliases = {
    update = "nix flake update --flake ${nixConfigPath}";
    check = "nix flake check ${nixConfigPath}";
    rebuild = "darwin-rebuild switch --flake ${nixConfigPath}";
  };

  videoAliases = {
    m4a = "${yt-dlp-script} m4a";
    "m4a-cut" = "${yt-dlp-script} m4a-cut";
    mp3 = "${yt-dlp-script} mp3";
    "mp3-cut" = "${yt-dlp-script} mp3";
    mp4 = "${yt-dlp-script} mp4";
    "mp4-cut" = "${yt-dlp-script} mp4-cut";
  };

  dirNavAliases = {
    ".." = "../";
    ".3" = "../../";
    ".4" = "../../..";
    ".5" = "../../../../";
  };

  mkAliases = aliases: lib.concatStringsSep "\n" (lib.mapAttrsToList mkAlias aliases);

  allAliases = lib.concatStringsSep "\n" (
    map mkAliases [
      programAliases
      fileOpAliases
      textProcAliases
      systemAliases
      timeAliases
      editorAliases
      nixAliases
      videoAliases
      dirNavAliases
    ]
  );
in
{
  programs.zsh = {
    enableSyntaxHighlighting = true;
    promptInit = ''
      source ${../../modules/home-manager/config/p10k.zsh}
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
    '';
    interactiveShellInit = ''
      source ${pkgs.oh-my-zsh}/share/oh-my-zsh/oh-my-zsh.sh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh

      eval "$(github-copilot-cli alias -- "$0")"

      # Aliases
      ${allAliases}
    '';
    variables = {
      SHELL = lib.getExe pkgs.zsh;
      ZDOTDIR = config.users.users.${username}.home;
    };
  };
}
