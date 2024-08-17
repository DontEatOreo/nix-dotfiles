{ pkgs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        # Git and GitHub related packages
        # gh # GitHub CLI
        # git # Git VCS
        gitty # Information about Git repositories
        gitflow # Git branching model
        github-copilot-cli # GitHub Copilot CLI
        jq
        cachix # Nix Binary Cache
        devenv # Manage development environment on Nix
        nixfmt-rfc-style # Upcomming new nix format, RFC 0160
        shellcheck # Warning hints for shell scripts

        # Terminal related packages
        delta # Better Diff
        thefuck # Correct previous command
        bc # Command line calculator
        nil # Nix language server
        ;
    };
  };
}
