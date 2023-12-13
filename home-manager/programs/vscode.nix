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
      # Enables VS Code to be used as a UI when connected to a remote server
      ms-vscode-remote.vscode-remote-extensionpack
      github.copilot # AI-powered coding assistant
      github.copilot-chat # Chat with GitHub Copilot
      vscode-icons-team.vscode-icons # Icons for Visual Studio Code
      ms-vsliveshare.vsliveshare # Real-time collaborative development
      visualstudioexptteam.vscodeintellicode

      # Language Specific Extensions
      ## Bash
      mads-hartmann.bash-ide-vscode # Bash language support

      ## Nix
      bbenoist.nix # Nix language support
      jnoortheen.nix-ide # Nix IDE features

      # C#
      ms-dotnettools.vscode-dotnet-runtime
      ms-dotnettools.csharp

      ## Java
      redhat.java # Java language support
      vscjava.vscode-java-pack # Java Extension Pack

      ## Python
      ms-python.python # Python language support
      ms-python.vscode-pylance # Python language server
      ms-toolsai.jupyter # Jupyter notebook support

      ## JS & TS
      ms-vscode.vscode-typescript-next # TypeScript language support
      mgmcdermott.vscode-language-babel # Babel language support
      steoates.autoimport # Auto import for JavaScript and TypeScript
      dbaeumer.vscode-eslint # ESLint support

      # Text Editing and Documentation
      davidanson.vscode-markdownlint # Linting for Markdown files
      james-yu.latex-workshop # LaTeX support
      redhat.vscode-xml # XML language support
      aykutsarac.jsoncrack-vscode # JSONCrack support

      # Utilities
      kamadorueda.alejandra # Alejandra, a Nix IDE
      mkhl.direnv # Direnv support
      oderwat.indent-rainbow # Colorful indentation
      esbenp.prettier-vscode # Code formatting with Prettier
      ryu1kn.partial-diff # Compare (diff) text selections within a file

      # Themes
      edwinsulaiman.jetbrains-rider-dark-theme # JetBrains Rider Dark Theme
      github.github-vscode-theme # GitHub's VS Code theme
    ];
    mutableExtensionsDir = false;
    userSettings = {
      # Bash
      "bashIde.explainshellEndpoint" = "http://localhost:5000";

      # Nix
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";

      # Diff Editor
      "diffEditor.ignoreTrimWhitespace" = false;

      # Theme
      "workbench.iconTheme" = "vscode-icons";
      "workbench.preferredLightColorTheme" = "JetBrains Rider Dark Theme";
      "workbench.preferredDarkColorTheme" = "JetBrains Rider Dark Theme";
      "workbench.colorTheme" = "JetBrains Rider Dark Theme";
      "window.autoDetectColorScheme" = true;
      "window.zoomLevel" = 1.5;

      # Editor
      "editor.mouseWheelZoom" = true;
      "editor.guides.bracketPairs" = "active";
      "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
      "security.workspace.trust.enabled" = false;
      "editor.accessibilitySupport" = "off";

      # Nix Editor
      "[nix]" = {
        "editor.defaultFormatter" = "kamadorueda.alejandra";
        "editor.formatOnPaste" = true;
        "editor.formatOnSave" = true;
        "editor.formatOnType" = false;
      };
      "alejandra.program" = "alejandra";

      # GitHub Copilot
      "github.copilot.enable" = {
        "*" = true;
        "plaintext" = false;
        "markdown" = false;
        "scminput" = false;
        "nix" = false;
        "lock" = false;
        "tape" = false;
      };

      # Other
      "redhat.telemetry.enabled" = false;

      # LaTeX
      "latex-workshop.latex.outDir" = "./output";
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
