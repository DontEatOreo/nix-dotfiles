{
  jq,
  lib,
  quickCss,
  runCommand,
  settings,
  writeText,
}:
let
  quickCssFile = writeText "equicord-quick-css" quickCss;
  settingsFile = writeText "equicord-settings.json" (builtins.toJSON settings);
in
runCommand "equicord-settings"
  {
    meta = {
      description = "Equicord settings shared by NixOS and non-NixOS installations";
      homepage = "https://github.com/4evy/dotfiles";
      license = lib.licenses.mit;
      maintainers = [ lib.maintainers._4evy ];
      platforms = lib.platforms.all;
    };
    nativeBuildInputs = [ jq ];
    strictDeps = true;
  }
  ''
    mkdir -p "$out"
    jq . ${settingsFile} > "$out/settings.json"
    cp ${quickCssFile} "$out/quickCss.css"
  ''
