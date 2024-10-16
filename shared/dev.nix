{ pkgs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        github-copilot-cli # GitHub Copilot CLI
        jq
        nixfmt-rfc-style # Upcomming new nix format, RFC 0160
        nixpkgs-review
        shellcheck # Warning hints for shell scripts

        # Terminal related packages
        delta # Better Diff
        bc # Command line calculator
        nil # Nix language server
        ;
    };
  };
}
