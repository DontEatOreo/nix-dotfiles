{
  pkgs,
  accent ? "mauve",
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "warp-terminal-catppuccin";
  version = "0-unstable-2024-07-20";

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "warp";
    rev = "7e3328b346ebe5ca7c59cfaa2b4bce755db62094";
    hash = "sha256-pUmO0po/fSPXIcKstWocCSX+Yg5l+H9JsEva+pCLNhI=";
  };

  nativeBuildInputs = builtins.attrValues { inherit (pkgs) just catppuccin-whiskers; };

  prePatch = ''
    substituteInPlace warp.tera \
      --replace-fail "rosewater" "${accent}"
  '';

  buildPhase = ''
    runHook preBuild
    rm -rf "themes/"
    just build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/warp/themes"
    cp themes/catppuccin_*.yml "$out/share/warp/themes/"
    runHook postInstall
  '';
}
