{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace-release;
in {
  programs.vscode = {
    enable = true;
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    extensions = with vscode-marketplace;
      [
        # Core Extensions
        editorconfig.editorconfig # Consistent coding styles between developers
        exodiusstudios.comment-anchors # Navigate through your code via comment anchors
        ms-vsliveshare.vsliveshare # Real-time collaborative development
        ms-vscode-remote.vscode-remote-extensionpack # Enables VS Code to be used as a UI when connected to a remote server
        visualstudioexptteam.vscodeintellicode
        vscode-icons-team.vscode-icons # Icons for Visual Studio Code

        # Language Specific Extensions
        ## Bash
        mads-hartmann.bash-ide-vscode # Bash language support

        ## C#
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit

        ## Java
        redhat.java # Java language support
        vscjava.vscode-java-pack # Java Extension Pack

        ## JS & TS
        dbaeumer.vscode-eslint # ESLint support
        gregorbiswanger.json2ts # Convert JSON objects to TypeScript interfaces
        mgmcdermott.vscode-language-babel # Babel language support
        ms-vscode.vscode-typescript-next # TypeScript language support
        steoates.autoimport # Auto import for JavaScript and TypeScript

        ## Nix
        bbenoist.nix # Nix language support
        jnoortheen.nix-ide # Nix IDE features

        ## Python
        ms-python.python # Python language support
        ms-python.vscode-pylance # Python language server
        ms-toolsai.jupyter # Jupyter notebook support

        ## VIM
        xadillax.viml

        # Text Editing and Documentation
        aykutsarac.jsoncrack-vscode # JSONCrack support
        davidanson.vscode-markdownlint # Linting for Markdown files
        james-yu.latex-workshop # LaTeX support
        redhat.vscode-xml # XML language support

        # Themes
        github.github-vscode-theme # GitHub's VS Code theme

        # Utilities
        esbenp.prettier-vscode # Code formatting with Prettier
        kamadorueda.alejandra # Opinionated Nix Formatter
        mkhl.direnv # Direnv support
        oderwat.indent-rainbow # Colorful indentation
        ryu1kn.partial-diff # Compare (diff) text selections within a file
      ]
      ++ (with vscode-marketplace-release; [
        github.copilot # AI-powered coding assistant
        github.copilot-chat # Chat with GitHub Copilot
      ]);
    mutableExtensionsDir = false;
    userSettings = {
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
    };
  };
}
