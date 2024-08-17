{ pkgs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        github-copilot-cli # GitHub Copilot CLI
        jq
        direnv
        devenv # Manage development environment on Nix
        nixfmt-rfc-style # Upcomming new nix format, RFC 0160
        shellcheck # Warning hints for shell scripts

        # Terminal related packages
        delta # Better Diff
        bc # Command line calculator
        nil # Nix language server
        ;
    };
  };
}
