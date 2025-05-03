{
  writeScriptBin,
  lib,
  osConfig,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isLinux;

  yt-dlp-script = lib.getExe (
    writeScriptBin "yt-dlp-script" (builtins.readFile ../shared/scripts/yt-dlp-script.sh)
  );

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
    dc = "z";
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
    update = "nix flake update --flake /etc/nixos";
    check = if isLinux then "nix flake check /etc/nixos" else "darwin-rebuild check --flake /etc/nixos";
    rebuild =
      if isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake /etc/nixos"
      else
        "darwin-rebuild switch --flake /etc/nixos";
    test = if isLinux then "nixos-rebuild test --flake /etc/nixos" else "true";
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
  };

  programs = {
    htop = "btop";
    neofetch = "fastfetch";
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
{
  aliases = date // directories // editors // misc // nix // operations // programs // video;
}
