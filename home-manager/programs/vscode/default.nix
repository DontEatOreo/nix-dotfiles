{
  inputs,
  pkgs,
  ...
}: let
  vscodeExtensions = import ./extensions.nix {inherit inputs pkgs;};
  userSettings = import ./settings.nix;
in {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = vscodeExtensions;
    mutableExtensionsDir = false;
    userSettings = userSettings;
  };
}
