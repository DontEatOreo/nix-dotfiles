{ lib, config, ... }:
{
  imports = [
    ./extensions.nix
    ./settings.nix
  ];

  options.hm.vscode.enable = lib.mkEnableOption "Enable VSCode";

  config = lib.mkIf config.hm.vscode.enable {
    programs.vscode = {
      enable = true;
      profiles.default.enableUpdateCheck = false;
      profiles.default.enableExtensionUpdateCheck = false;
      mutableExtensionsDir = false;
    };
  };
}
