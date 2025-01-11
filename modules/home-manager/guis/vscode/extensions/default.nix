{
  inputs,
  pkgs,
  config,
  system,
  ...
}:
let
  inherit
    (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version)
    vscode-marketplace
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
      ## Linting for Markdown files
      vscode-markdownlint = vscode-marketplace.davidanson.vscode-markdownlint;
      ## LaTeX support
      latex-workshop = vscode-marketplace.james-yu.latex-workshop;
      ## XML language support
      vscode-xml = vscode-marketplace.redhat.vscode-xml;

      ## Catppuccin
      catppuccin-vsc = inputs.catppuccin-vsc.packages.${system}.catppuccin-vsc.override {
        inherit (config.catppuccin) accent;
      };
      catppuccin-vsc-icons = vscode-marketplace.catppuccin.catppuccin-vsc-icons;

      # Utilities
      ## Code formatting with Prettier
      prettier-vscode = vscode-marketplace.esbenp.prettier-vscode;
      ## Direnv support
      direnv = vscode-marketplace.mkhl.direnv;
      ## Colorful indentation
      indent-rainbow = vscode-marketplace.oderwat.indent-rainbow;

      # Release
      copilot = pkgs.vscode-extensions.github.copilot;
      copilot-chat = pkgs.vscode-extensions.github.copilot-chat;
    };
  };
}
