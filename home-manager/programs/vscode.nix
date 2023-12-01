{
  inputs,
  system,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${system}) vscode-marketplace;
in {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = with vscode-marketplace; [
      # Core Extensions
      ms-vscode-remote.vscode-remote-extensionpack
      github.copilot
      github.copilot-chat
      vscode-icons-team.vscode-icons
      ms-vsliveshare.vsliveshare

      # Language Specific Extensions
      ## Bash
      mads-hartmann.bash-ide-vscode

      ## Nix
      bbenoist.nix
      jnoortheen.nix-ide

      ## C#
      ms-dotnettools.csharp

      ## Java
      redhat.java
      vscjava.vscode-java-pack

      ## Python
      ms-python.python
      ms-python.vscode-pylance
      ms-toolsai.jupyter

      ## JS & TS
      ms-vscode.vscode-typescript-next
      mgmcdermott.vscode-language-babel
      steoates.autoimport
      dbaeumer.vscode-eslint

      # Text Editing and Documentation
      davidanson.vscode-markdownlint
      james-yu.latex-workshop
      redhat.vscode-xml
      redhat.vscode-xml
      aykutsarac.jsoncrack-vscode
      streetsidesoftware.code-spell-checker

      # Utilities
      kamadorueda.alejandra
      mkhl.direnv
      oderwat.indent-rainbow
      esbenp.prettier-vscode
      ryu1kn.partial-diff

      # Themes
      edwinsulaiman.jetbrains-rider-dark-theme
      github.github-vscode-theme
    ];
    mutableExtensionsDir = true;
    userSettings = {
      # Bash
      "bashIde.explainshellEndpoint" = "http://localhost:5000";

      # Nix
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";

      "diffEditor.ignoreTrimWhitespace" = false;

      # Theme
      "workbench.iconTheme" = "vscode-icons";
      "workbench.preferredLightColorTheme" = "JetBrains Rider New UI Dark";
      "workbench.preferredDarkColorTheme" = "JetBrains Rider New UI Dark";
      "workbench.colorTheme" = "JetBrains Rider New UI Dark";
      "window.autoDetectColorScheme" = true;

      "window.zoomLevel" = 1.5;

      # Editor Stuff
      "editor.mouseWheelZoom" = true;
      "editor.guides.bracketPairs" = "active";
      "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
      "security.workspace.trust.enabled" = false;

      "latex-workshop.latex.outDir" = "./output";
      "[nix]" = {
        "editor.defaultFormatter" = "kamadorueda.alejandra";
        "editor.formatOnPaste" = true;
        "editor.formatOnSave" = true;
        "editor.formatOnType" = false;
      };
      "alejandra.program" = "alejandra";

      "github.copilot.enable" = {
        "*" = true;
        "plaintext" = false;
        "markdown" = false;
        "scminput" = false;
        "nix" = false;
        "lock" = false;
      };

      # Other
      "editor.accessibilitySupport" = "off";

      # LaTeX Stuff
      "latex-workshop.latex.recipes" = [
        {
          "name" = "xeLaTeX -> Biber -> xeLaTeX";
          "tools" = [
            "xelatex"
            "biber"
            "xelatex"
          ];
        }
        {
          "name" = "xeLaTeX -> pdflatex";
          "tools" = [
            "xelatex"
            "pdflatex"
          ];
        }
      ];

      "latex-workshop.latex.tools" = [
        {
          "name" = "xelatex";
          "command" = "xelatex";
          "args" = [
            "-synctex=1"
            "-interaction=nonstopmode"
            "-file-line-error"
            "-shell-escape"
            "-output-directory=output"
            "%DOC%"
          ];
        }
        {
          "name" = "biber";
          "command" = "biber";
          "args" = [
            "--output-directory=output"
            "%DOCFILE%"
          ];
        }
        {
          "name" = "pdflatex";
          "command" = "pdflatex";
          "args" = [
            "-synctex=1"
            "-interaction=nonstopmode"
            "-file-line-error"
            "-shell-escape"
            "-output-directory=output"
            "%DOC%"
          ];
        }
      ];
    };
  };
}
