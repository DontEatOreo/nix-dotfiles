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
      vscodeintellicode = vscode-marketplace.visualstudioexptteam.vscodeintellicode;
    };
  };
}
