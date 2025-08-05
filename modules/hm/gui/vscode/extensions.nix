{
  config,
  osConfig,
  myLib,
  ...
}:
let
  s = { inherit (osConfig.nixpkgs.hostPlatform) system; };
  inherit (myLib) mkExt;
in
{
  programs.vscode.profiles.default.extensions = [
    # Utils
    (mkExt s "esbenp" "prettier-vscode")
    (mkExt s "mkhl" "direnv")
    (mkExt s "oderwat" "indent-rainbow")
    (mkExt s "visualstudioexptteam" "vscodeintellicode")
    (mkExt s "editorconfig" "editorconfig")

    # Languages
    # Bash
    (mkExt s "mads-hartmann" "bash-ide-vscode")
    (mkExt s "timonwong" "shellcheck")

    # JS & TS
    (mkExt s "dbaeumer" "vscode-eslint")
    (mkExt s "mgmcdermott" "vscode-language-babel")

    # Nix
    (mkExt s "bbenoist" "nix")
    (mkExt s "jnoortheen" "nix-ide")
    (mkExt s "kamadorueda" "alejandra")

    # Markdown & Docs
    (mkExt s "davidanson" "vscode-markdownlint")
    (mkExt s "redhat" "vscode-xml")
  ];

  programs.vscode.profiles.default.userSettings = {
    # Theme
    "workbench.iconTheme" = "catppuccin-${config.catppuccin.flavor}";

    # Language specific formatters
    "[nix]" = {
      "editor.defaultFormatter" = "kamadorueda.alejandra";
      "editor.formatOnPaste" = true;
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnPaste" = true;
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnPaste" = true;
      "editor.formatOnSave" = true;
      "editor.formatOnType" = true;
    };

    # Language server settings
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "nil";
    "alejandra.program" = "nixfmt";
    "bashIde.explainshellEndpoint" = "http://localhost:5134";

    # RedHat XML
    "redhat.telemetry.enabled" = false;
  };
}
