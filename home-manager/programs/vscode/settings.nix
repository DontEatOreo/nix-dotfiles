{
  # Git
  "git.enableCommitSigning" = true; # Make sure to set up GPG and GIT first...

  # Bash
  "bashIde.explainshellEndpoint" = "http://localhost:5134";

  # Nix
  "nix.enableLanguageServer" = true;
  "nix.serverPath" = "nil";

  # Diff Editor
  "diffEditor.ignoreTrimWhitespace" = false;

  # Theme
  "workbench.iconTheme" = "vscode-icons";
  "workbench.colorTheme" = "GitHub Dark Dimmed";
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
}
