{
  # Git
  "git.enableCommitSigning" = true; # Make sure to set up GPG and GIT first...

  # Bash
  "bashIde.explainshellEndpoint" = "http://localhost:5134";

  # Diff Editor
  "diffEditor.ignoreTrimWhitespace" = false;

  # Theme
  "workbench.iconTheme" = "vscode-icons";
  "workbench.colorTheme" = "Quiet Light";
  "workbench.preferredLightColorTheme" = "GitHub Light";
  "workbench.preferredDarkColorTheme" = "GitHub Dark Dimmed";
  "window.autoDetectColorScheme" = true;
  "window.zoomLevel" = 1.5;

  # Editor
  "editor.mouseWheelZoom" = true;
  "editor.guides.bracketPairs" = "active";
  "editor.bracketPairColorization.independentColorPoolPerBracketType" = true;
  "security.workspace.trust.enabled" = false;
  "editor.accessibilitySupport" = "off";

  # Nix
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "nil";

  # Formaters
  ## Nix formatter
  "alejandra.program" = "alejandra";
  "[nix]" = {
    "editor.defaultFormatter" = "kamadorueda.alejandra";
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = false;
  };

  ## Python formatter
  "[python]" = {
    "editor.defaultFormatter" = "ms-python.black-formatter";
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = false;
  };
  ## JavaScript formatter
  "[javascript]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = false;
  };

  # TypeScript formatter
  "[typescript]" = {
    "editor.defaultFormatter" = "esbenp.prettier-vscode";
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = false;
  };

  ## Java formatter
  "[java]" = {
    "editor.defaultFormatter" = "redhat.java";
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = false;
  };

  ## C# formatter
  "[csharp]" = {
    "editor.defaultFormatter" = "ms-dotnettools.csharp";
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = false;
  };

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
}
