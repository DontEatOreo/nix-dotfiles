{
  pkgs,
  lib,
  nixCfgPath,
}:
let
  yt-dlp-script = lib.getExe (
    pkgs.writeScriptBin "yt-dlp-script" (builtins.readFile ../shared/scripts/yt-dlp-script.sh)
  );

  mergeAttrs =
    attrsList:
    builtins.foldl' (
      acc: set:
      acc
      // builtins.mapAttrs (
        k: v: if builtins.isString v && builtins.match ".*[^ ]$" v != null then "${v} " else v
      ) set
    ) { } attrsList;

  date = {
    now = "date +'%T'";
    nowtime = "now";
    nowdate = "date +'%d-%m-%Y'";
  };

  directories = {
    ".." = "../";
    ".3" = "../../";
    ".4" = "../../..";
    ".5" = "../../../../";
    cd = "z";
    dc = "zi";
  };

  editors = {
    v = "hx";
    vi = "hx";
    vim = "hx";
    h = "hx";
  };

  misc = {
    bc = "bc -l";
    xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
  };

  nix = {
    update = "nix flake update --flake ${nixCfgPath}";
    check =
      if pkgs.stdenvNoCC.hostPlatform.isLinux then
        "nix flake check ${nixCfgPath}"
      else
        "darwin-rebuild check --flake ${nixCfgPath}";
    rebuild =
      if pkgs.stdenvNoCC.hostPlatform.isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake ${nixCfgPath}"
      else
        "darwin-rebuild switch --flake ${nixCfgPath}";
    test =
      if pkgs.stdenvNoCC.hostPlatform.isLinux then "nixos-rebuild test --flake ${nixCfgPath}" else "true";
  };

  operations = {
    ls = "eza --oneline";
    lt = "eza --oneline --reverse --sort=size --size";
    ll = "eza --long";
    ld = "ls -d .*";
    mv = "mv -iv";
    cp = "cp -iv";
    rm = "rm -v";
    mkdir = "mkdir -pv";
    untar = "tar -zxvf";
    du = "dust";
    find = "fd";
  };

  programs = {
    htop = "btop";
    neofetch = "fastfetch";
  };

  text = {
    grep = "rg";
    diff = "delta";
    cat = "bat";
    sed = "sd";
  };

  video = {
    m4a = "${yt-dlp-script} m4a";
    m4a-cut = "${yt-dlp-script} m4a-cut";
    mp3 = "${yt-dlp-script} mp3";
    mp3-cut = "${yt-dlp-script} mp3-cut";
    mp4 = "${yt-dlp-script} mp4";
    mp4-cut = "${yt-dlp-script} mp4-cut";
  };
in
mergeAttrs [
  date
  directories
  editors
  misc
  nix
  operations
  programs
  text
  video
]
