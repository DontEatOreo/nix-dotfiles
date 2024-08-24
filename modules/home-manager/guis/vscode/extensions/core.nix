{ inputs, pkgs, ... }:
let
  inherit
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version)
    vscode-marketplace
    ;
in
{
  programs.vscode = {
    extensions = builtins.attrValues {
      # Consistent coding styles between developers
      editorconfig = vscode-marketplace.editorconfig.editorconfig;
      # Navigate through your code via comment anchors
      comment-anchors = vscode-marketplace.exodiusstudios.comment-anchors;
      # Real-time collaborative development
      vsliveshare = vscode-marketplace.ms-vsliveshare.vsliveshare;
      vscodeintellicode = vscode-marketplace.visualstudioexptteam.vscodeintellicode;
    };
  };
}
