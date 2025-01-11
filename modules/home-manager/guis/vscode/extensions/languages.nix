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
      # Bash
      bash-ide-vscode = vscode-marketplace.mads-hartmann.bash-ide-vscode;
      shellcheck = vscode-marketplace.timonwong.shellcheck;

      # JS & TS
      vscode-eslint = vscode-marketplace.dbaeumer.vscode-eslint;
      vscode-language-babel = vscode-marketplace.mgmcdermott.vscode-language-babel;

      # Nix
      nix = vscode-marketplace.bbenoist.nix;
      nix-ide = vscode-marketplace.jnoortheen.nix-ide;
      ## Opinionated Nix Formatter
      alejandra = vscode-marketplace.kamadorueda.alejandra;

      # VIM
      viml = vscode-marketplace.xadillax.viml;
    };
  };
}
