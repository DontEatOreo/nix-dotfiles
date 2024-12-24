{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      bc # Command line calculator
      delta # Better Diff
      github-copilot-cli # GitHub Copilot CLI
      jq
      neovim
      nil # Nix language server
      nixfmt-rfc-style
      nixpkgs-review
      shellcheck # Warning hints for shell scripts
      ;
  };
}
