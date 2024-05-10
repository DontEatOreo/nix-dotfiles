{pkgs, ...}: {
  environment = {
    systemPackages = builtins.attrValues {
      inherit
        (pkgs)
        # Git and GitHub related packages
        
        gh # GitHub CLI
        git # Git VCS
        gitty # Information about Git repositories
        gitflow # Git branching model
        github-copilot-cli # GitHub Copilot CLI
        jq
        devenv # Manage development environment on Nix
        # Terminal related packages
        
        colordiff # Colorize diff output
        thefuck # Correct previous command
        bc # Command line calculator
        nil # Nix language server
        ;
    };
  };
}
