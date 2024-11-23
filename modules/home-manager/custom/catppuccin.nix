{
  pkgs,
  lib,
  flavor ? "frappe",
  accent ? "mauve",
  ...
}:

let
  capitalizeFirst =
    str:
    let
      first = builtins.substring 0 1 str;
      rest = builtins.substring 1 (builtins.stringLength str) str;
    in
    (lib.strings.toUpper first) + rest;

  normalizedFlavor = capitalizeFirst (
    builtins.replaceStrings [ "frappe" ] [ "frappé" ] (lib.strings.toLower flavor)
  );
  normalizedAccent = capitalizeFirst (lib.strings.toLower accent);
in
assert
  builtins.replaceStrings [ "é" ] [ "e" ] (lib.strings.toLower normalizedFlavor)
  == lib.strings.toLower flavor;
assert lib.strings.toLower accent == lib.strings.toLower normalizedAccent;

pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "catppuccin-userstyles";
  version = "all-userstyles-export-unstable-2024-11-20";

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "userstyles";
    rev = "026cc18e48ee3b57b2b4995b4dc560b3c333bc6d";
    hash = "sha256-UPkYiQworwd5n+FsO6lOXdBfu5JEj/RI0Sx++Yi5MtI=";
  };

  buildInputs = builtins.attrValues { inherit (pkgs) deno; };

  # Set up temporary directories that Deno can write to
  # See: https://docs.deno.com/runtime/getting_started/setup_your_environment/#deno_dir-environment-variable
  # See: https://docs.deno.com/runtime/fundamentals/modules/#deno_dir-environment-variable
  preBuild = ''
    export DENO_DIR="$TMPDIR/deno"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export HOME="$TMPDIR/home"
    mkdir -p "$DENO_DIR"
    mkdir -p "$XDG_CACHE_HOME"
    mkdir -p "$HOME"
  '';

  buildPhase = ''
    runHook preBuild

    deno run --allow-read --allow-write --allow-net ./scripts/stylus-import/main.ts
    sed -i \
      -e 's/"default":"mocha"/"default":"'"${flavor}"'"/g' \
      -e 's/"default":"mauve"/"default":"'"${accent}"'"/g' \
      -e 's/mocha:Mocha\*"/'${flavor}':'"${normalizedFlavor}"'\*"/g' \
      -e 's/mauve:Mauve\*"/'${accent}':'"${normalizedAccent}"'\*"/g' \
      dist/import.json
      
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/dist"
    cp -r "dist/import.json" $out/dist/
    runHook postInstall
  '';
})
