{
  writeScriptBin,
  getExe,
  system,
  nixConfigPath,
}:
let
  isLinux = builtins.match ".*linux.*" system != null;

  yt-dlp-script = getExe (
    writeScriptBin "yt-dlp-script" (builtins.readFile ../shared/scripts/yt-dlp-script.sh)
  );

  mergeAttrs = attrsList: builtins.foldl' (acc: set: acc // set) { } attrsList;

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
  };

  editors = {
    v = "nvim";
    vi = "nvim";
    vim = "nvim";
  };

  misc = {
    bc = "bc -l";
    xdg-data-dirs = "echo -e $XDG_DATA_DIRS | tr ':' '\n' | nl | sort";
  };

  nix = {
    update = "nix flake update --flake ${nixConfigPath}";
    check =
      if isLinux then
        "nix flake check ${nixConfigPath}"
      else
        "darwin-rebuild check --flake ${nixConfigPath}";
    rebuild =
      if isLinux then
        "nixos-rebuild switch --use-remote-sudo --flake ${nixConfigPath}"
      else
        "darwin-rebuild switch --flake ${nixConfigPath}";
    test = if isLinux then "nixos-rebuild test --flake ${nixConfigPath}" else "true";
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
