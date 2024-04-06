{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
in {
  programs.vscode = {
    extensions = with vscode-marketplace; [
      # Bash
      mads-hartmann.bash-ide-vscode

      # C#
      ms-dotnettools.csharp
      ms-dotnettools.csdevkit
      ms-dotnettools.vscode-dotnet-runtime
      ms-dotnettools.vscodeintellicode-csharp

      # Java
      redhat.java
      vscjava.vscode-java-pack

      # JS & TS
      dbaeumer.vscode-eslint
      gregorbiswanger.json2ts # Convert JSON objects to TypeScript interfaces
      mgmcdermott.vscode-language-babel
      ms-vscode.vscode-typescript-next
      steoates.autoimport

      # Nix
      bbenoist.nix
      jnoortheen.nix-ide
      kamadorueda.alejandra # Opinionated Nix Formatter

      # Python
      ms-python.Python
      ms-python.vscode-pylance # Python language server
      ms-python.black-formatter

      # VIM
      xadillax.viml
    ];
  };
}
