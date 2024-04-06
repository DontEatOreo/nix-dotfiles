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
      mads-hartmann.bash-ide-vscode # Bash language support

      # C#
      ms-dotnettools.csharp
      ms-dotnettools.csdevkit
      ms-dotnettools.vscode-dotnet-runtime
      ms-dotnettools.vscodeintellicode-csharp

      # Java
      redhat.java # Java language support
      vscjava.vscode-java-pack # Java Extension Pack

      # JS & TS
      dbaeumer.vscode-eslint # ESLint support
      gregorbiswanger.json2ts # Convert JSON objects to TypeScript interfaces
      mgmcdermott.vscode-language-babel # Babel language support
      ms-vscode.vscode-typescript-next # TypeScript language support
      steoates.autoimport # Auto import for JavaScript and TypeScript

      # Nix
      bbenoist.nix # Nix language support
      jnoortheen.nix-ide # Nix IDE features
      kamadorueda.alejandra # Opinionated Nix Formatter

      # Python
      ms-python.python # Python language support
      ms-python.vscode-pylance # Python language server
      ms-python.black-formatter # Format Python Code

      # VIM
      xadillax.viml
    ];
  };
}
