{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isLinux;

  yt-dlp-script = lib.getExe (
    pkgs.writeShellApplication {
      name = "yt-dlp-script";
      text = (builtins.readFile ../scripts/yt-dlp-script.sh);
      runtimeInputs = builtins.attrValues {
        inherit (pkgs)
          bc
          cacert
          choose
          dust
          fd
          ffmpeg_7-full
          gum
          jq
          sd
          yt-dlp
          ;
      };
    }
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
    update = "nix flake update --flake $(readlink -f /etc/nixos)";
    check =
      if isLinux then
        "nix flake check $(readlink -f /etc/nixos)"
      else
        "sudo darwin-rebuild check --flake $(readlink -f /etc/nixos)";
    rebuild =
      if isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake $(readlink -f /etc/nixos)"
      else
        "sudo darwin-rebuild switch --flake $(readlink -f /etc/nixos)";
    test = if isLinux then "nixos-rebuild test --flake $(readlink -f /etc/nixos)" else "true";
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

  merged = date // directories // editors // misc // nix // operations // programs // video;
in
{
  programs.bash.shellAliases = merged;
  programs.zsh.shellAliases = merged;
}
