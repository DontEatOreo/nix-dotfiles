{
  inputs,
  pkgs,
  config,
  ...
}:
let
  inherit
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version)
    vscode-marketplace
    ;

  mkExt = publisher: extension: vscode-marketplace.${publisher}.${extension};

  utils = [
    (mkExt "esbenp" "prettier-vscode")
    (mkExt "mkhl" "direnv")
    (mkExt "oderwat" "indent-rainbow")
    (mkExt "visualstudioexptteam" "vscodeintellicode")
    (mkExt "editorconfig" "editorconfig")
    pkgs.vscode-extensions.github.copilot
    pkgs.vscode-extensions.github.copilot-chat
  ];

  themes = [
    (inputs.catppuccin-vsc.packages.${pkgs.system}.catppuccin-vsc.override {
      inherit (config.catppuccin) accent;
    })
    vscode-marketplace.catppuccin.catppuccin-vsc-icons
  ];

  languages = [
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

in
{
  programs.vscode.extensions = utils ++ themes ++ languages;
}
