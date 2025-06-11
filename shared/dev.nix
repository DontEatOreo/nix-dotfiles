{
  pkgs,
  inputs,
  config,
  ...
}:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      bc # Command line calculator
      delta # Better Diff
      github-copilot-cli # GitHub Copilot CLI
      jq
      nixfmt-rfc-style
      nixpkgs-review
      shellcheck # Warning hints for shell scripts
      cargo
      ;
    inherit (inputs.rust-overlay.packages.${config.nixpkgs.hostPlatform.system}) default;
    nil = inputs.nil.packages.${config.nixpkgs.hostPlatform.system}.nil; # Nix language server
  };
}
