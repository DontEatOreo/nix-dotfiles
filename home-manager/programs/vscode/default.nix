_: {
  imports = [
    ./extensions.nix
    ./settings.nix
  ];

  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    mutableExtensionsDir = false;
  };
}
