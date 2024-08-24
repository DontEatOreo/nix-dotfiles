{ lib, config, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  imports = [
    ./extensions
    ./settings.nix
  ];

  options.hm.vscode.enable = mkEnableOption "Enable VSCode";

  config = mkIf config.hm.vscode.enable {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;
    };
  };
}
