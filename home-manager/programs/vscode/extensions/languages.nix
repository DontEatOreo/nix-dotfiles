{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
in {
  programs.vscode = {
    extensions = builtins.attrValues {
      # Bash
      bash-ide-vscode = vscode-marketplace.mads-hartmann.bash-ide-vscode;

      # C#
      csharp = vscode-marketplace.ms-dotnettools.csharp;
      csdevkit = vscode-marketplace.ms-dotnettools.csdevkit;
      vscode-dotnet-runtime = vscode-marketplace.ms-dotnettools.vscode-dotnet-runtime;
      vscodeintellicode-csharp = vscode-marketplace.ms-dotnettools.vscodeintellicode-csharp;

      # JS & TS
      vscode-eslint = vscode-marketplace.dbaeumer.vscode-eslint;
      ## Convert JSON objects to TypeScript interfaces
      json2ts = vscode-marketplace.gregorbiswanger.json2ts;
      vscode-language-babel = vscode-marketplace.mgmcdermott.vscode-language-babel;
      vscode-typescript-next = vscode-marketplace.ms-vscode.vscode-typescript-next;
      autoimport = vscode-marketplace.steoates.autoimport;

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
