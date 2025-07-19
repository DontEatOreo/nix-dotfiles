{
  pkgs,
  accent ? "mauve",
  ...
}:
pkgs.stdenvNoCC.mkDerivation {
  pname = "warp-terminal-catppuccin";
  version = "0-unstable-2025-03-09";

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "warp";
    rev = "b6891cc339b3a1bb70a5c3063add4bdbd0455603";
    hash = "sha256-ypzSeSWT2XfdjfdeE/lLdiRgRmxewAqiWhGp6jjF7hE=";
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
