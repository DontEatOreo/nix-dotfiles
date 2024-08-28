{ lib, config, ... }:
{
  imports = [
    ./extensions
    ./settings.nix
  ];

  options.hm.vscode.enable = lib.mkEnableOption "Enable VSCode";

  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode = {
      enable = true;
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;
    };
  };
}
