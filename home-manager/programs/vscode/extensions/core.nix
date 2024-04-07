{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
in {
  programs.vscode = {
    extensions = builtins.attrValues {
      # Consistent coding styles between developers
      editorconfig = vscode-marketplace.editorconfig.editorconfig;
      # Navigate through your code via comment anchors
      comment-anchors = vscode-marketplace.exodiusstudios.comment-anchors;
      # Real-time collaborative development
      vsliveshare = vscode-marketplace.ms-vsliveshare.vsliveshare;
      # Enables VS Code to be used as a UI when connected to a remote server
      vscode-remote-extensionpack = vscode-marketplace.ms-vscode-remote.vscode-remote-extensionpack;
      vscodeintellicode = vscode-marketplace.visualstudioexptteam.vscodeintellicode;
      # Icons for Visual Studio Code
      vscode-icons = vscode-marketplace.vscode-icons-team.vscode-icons;
    };
  };
}
