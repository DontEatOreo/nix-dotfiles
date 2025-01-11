{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version)
    vscode-marketplace
    ;
  mkExt = p: e: vscode-marketplace.${p}.${e};

  mkFormatterConfig = f: {
    "editor.defaultFormatter" = f;
    "editor.formatOnPaste" = true;
    "editor.formatOnSave" = true;
    "editor.formatOnType" = true;
  };

  utils = {
    extensions = [
      (mkExt "esbenp" "prettier-vscode")
      (mkExt "mkhl" "direnv")
      (mkExt "oderwat" "indent-rainbow")
      (mkExt "visualstudioexptteam" "vscodeintellicode")
      (mkExt "editorconfig" "editorconfig")
      pkgs.vscode-extensions.github.copilot
      pkgs.vscode-extensions.github.copilot-chat
    ];
    settings = {
      github.copilot.enable = {
        "*" = true;
        css = false;
        json = false;
        lock = false;
        markdown = false;
        nix = false;
        plaintext = false;
        scminput = false;
        tape = false;
      };
    };
  };

  themes = {
    extensions = [
      (inputs.catppuccin-vsc.packages.${pkgs.system}.catppuccin-vsc.override {
        inherit (config.catppuccin) accent;
      })
      vscode-marketplace.catppuccin.catppuccin-vsc-icons
    ];
    settings =
      let
        capitalizeFirst =
          str:
          let
            firstChar = builtins.substring 0 1 str;
            middlePart = builtins.substring 1 4 str;
          in
          if str == "frappe" then
            (lib.toUpper firstChar) + middlePart + "é"
          else
            (lib.toUpper firstChar) + (builtins.substring 1 (builtins.stringLength str) str);
      in
      {
        workbench.iconTheme = "catppuccin-${config.catppuccin.flavor}";
        workbench.colorTheme = "Catppuccin ${capitalizeFirst config.catppuccin.flavor}";
      };
  };

  languages = {
    extensions = [
      # Bash
      (mkExt "mads-hartmann" "bash-ide-vscode")
      (mkExt "timonwong" "shellcheck")

      # JS & TS
      (mkExt "dbaeumer" "vscode-eslint")
      (mkExt "mgmcdermott" "vscode-language-babel")

      # Nix
      (mkExt "bbenoist" "nix")
      (mkExt "jnoortheen" "nix-ide")
      (mkExt "kamadorueda" "alejandra")

      # VIM
      (mkExt "xadillax" "viml")

      # Markdown & Docs
      (mkExt "davidanson" "vscode-markdownlint")
      (mkExt "james-yu" "latex-workshop")
      (mkExt "redhat" "vscode-xml")
    ];
    settings = {
      "[nix]" = mkFormatterConfig "kamadorueda.alejandra";
      "[javascript]" = mkFormatterConfig "esbenp.prettier-vscode";
      "[typescript]" = mkFormatterConfig "esbenp.prettier-vscode";

      # Language server settings
      nix.enableLanguageServer = true;
      nix.serverPath = "nil";
      alejandra.program = "nixfmt";
      bashIde.explainshellEndpoint = "http://localhost:5134";

      # LaTeX settings
      latex-workshop.latex = {
        outDir = "./output";
        recipes = [
          {
            name = "xeLaTeX -> Biber -> xeLaTeX";
            tools = [
              "xelatex"
              "biber"
              "xelatex"
            ];
          }
          {
            name = "xeLaTeX -> pdflatex";
            tools = [
              "xelatex"
              "pdflatex"
            ];
          }
        ];
        tools =
          let
            commonLatexArgs = [
              "-synctex=1"
              "-interaction=nonstopmode"
              "-file-line-error"
              "-shell-escape"
              "-output-directory=output"
              "%DOC%"
            ];
            mkLatexTool = name: command: args: {
              inherit name command args;
            };
          in
          [
            (mkLatexTool "xelatex" "xelatex" commonLatexArgs)
            (mkLatexTool "biber" "biber" [
              "--output-directory=output"
              "%DOCFILE%"
            ])
            (mkLatexTool "pdflatex" "pdflatex" commonLatexArgs)
          ];
      };
      # RedHat XML
      redhat.telemetry.enabled = false;
    };
  };

  flattenAttrs =
    attrs: excludePaths:
    let
      isAttrSet = v: builtins.isAttrs v && !builtins.isList v;
      isExcluded = path: lib.any (excludePath: path == excludePath) excludePaths;

      # Convert nested set to flat dot-notation
      go =
        prefix: set:
        lib.concatMap (
          name:
          let
            value = set.${name};
            newPrefix = if prefix == "" then name else "${prefix}.${name}";
          in
          if isExcluded newPrefix then
            [
              {
                name = newPrefix;
                value = value;
              }
            ]
          else if isAttrSet value then
            go newPrefix value
          else
            [
              {
                name = newPrefix;
                value = value;
              }
            ]
        ) (builtins.attrNames set);
    in
    builtins.listToAttrs (go "" attrs);

  mergeFrom =
    let
      modules = [
        utils
        themes
        languages
      ];
      excludePaths = [
        "[javascript]"
        "[nix]"
        "[typescript]"
        "github.copilot.enable"
      ];
    in
    p:
    if p == "extensions" then
      lib.concatLists (map (module: module.${p}) modules)
    else
      flattenAttrs (lib.foldl' (
        acc: module: lib.recursiveUpdate acc module.${p}
      ) { } modules) excludePaths;
in
{
  programs.vscode.extensions = mergeFrom "extensions";
  programs.vscode.userSettings = mergeFrom "settings";
}
