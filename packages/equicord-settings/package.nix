{
  jq,
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
    meta.description = "Equicord settings shared by NixOS and non-NixOS installations";
    nativeBuildInputs = [ jq ];
    strictDeps = true;
  }
  ''
    mkdir -p "$out"
    jq . ${settingsFile} > "$out/settings.json"
    cp ${quickCssFile} "$out/quickCss.css"
  ''
