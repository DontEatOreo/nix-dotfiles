{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
in {
  programs.vscode = {
    extensions = with vscode-marketplace; [
      # Core Extensions
      editorconfig.editorconfig # Consistent coding styles between developers
      exodiusstudios.comment-anchors # Navigate through your code via comment anchors
      ms-vsliveshare.vsliveshare # Real-time collaborative development
      ms-vscode-remote.vscode-remote-extensionpack # Enables VS Code to be used as a UI when connected to a remote server
      visualstudioexptteam.vscodeintellicode
      vscode-icons-team.vscode-icons # Icons for Visual Studio Code
    ];
  };
}
