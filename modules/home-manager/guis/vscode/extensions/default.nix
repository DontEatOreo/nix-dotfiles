{ inputs, pkgs, ... }:
let
  inherit
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version)
    vscode-marketplace
    ;
  inherit
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version)
    vscode-marketplace-release
    ;
in
{
  imports = [
    ./core.nix
    ./languages.nix
  ];

  programs.vscode = {
    extensions = builtins.attrValues {
      # Text Editing and Documentation
      ## JSONCrack support
      jsoncrack-vscode = vscode-marketplace.aykutsarac.jsoncrack-vscode;
      ## Linting for Markdown files
      vscode-markdownlint = vscode-marketplace.davidanson.vscode-markdownlint;
      ## LaTeX support
      latex-workshop = vscode-marketplace.james-yu.latex-workshop;
      ## XML language support
      vscode-xml = vscode-marketplace.redhat.vscode-xml;

      # Themes
      ## GitHub's VS Code theme
      github-vscode-theme = vscode-marketplace.github.github-vscode-theme;

      ## Catppuccin
      catppuccin-vsc = vscode-marketplace.catppuccin.catppuccin-vsc;
      catppuccin-vsc-icons = vscode-marketplace.catppuccin.catppuccin-vsc-icons;

      # Utilities
      ## Code formatting with Prettier
      prettier-vscode = vscode-marketplace.esbenp.prettier-vscode;
      ## Direnv support
      direnv = vscode-marketplace.mkhl.direnv;
      ## Colorful indentation
      indent-rainbow = vscode-marketplace.oderwat.indent-rainbow;
      ## Compare (diff) text selections within a file
      partial-diff = vscode-marketplace.ryu1kn.partial-diff;

      # Release
      copilot = vscode-marketplace-release.github.copilot;
      copilot-chat = vscode-marketplace-release.github.copilot-chat;
    };
  };
}
