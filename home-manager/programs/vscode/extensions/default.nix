{
  inputs,
  pkgs,
  ...
}: let
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace;
  inherit (inputs.nix-vscode-extensions.extensions.${pkgs.system}.forVSCodeVersion pkgs.vscode.version) vscode-marketplace-release;
in {
  imports = [
    ./core.nix
    ./languages.nix
  ];

  programs.vscode = {
    extensions = with vscode-marketplace;
      [
        # Text Editing and Documentation
        aykutsarac.jsoncrack-vscode # JSONCrack support
        davidanson.vscode-markdownlint # Linting for Markdown files
        james-yu.latex-workshop # LaTeX support
        redhat.vscode-xml # XML language support

        # Themes
        github.github-vscode-theme # GitHub's VS Code theme

        # Utilities
        esbenp.prettier-vscode # Code formatting with Prettier
        mkhl.direnv # Direnv support
        oderwat.indent-rainbow # Colorful indentation
        ryu1kn.partial-diff # Compare (diff) text selections within a file
      ]
      ++ (with vscode-marketplace-release; [
        github.copilot # AI-powered coding assistant
        github.copilot-chat # Chat with GitHub Copilot
      ]);
  };
}
