{pkgs, ...}: {
  imports = [
    ./pythonPackages.nix
    ./dotnetSdks.nix
  ];

  environment = {
    systemPackages = with pkgs; [
      # Git and GitHub related packages
      gh # GitHub CLI
      git # Git VCS
      gitty # Information about Git repositories
      gitui # Terminal UI for Git
      gitflow # Git branching model
      github-copilot-cli # GitHub Copilot CLI
      jq

      # Terminal related packages
      colordiff # Colorize diff output
      thefuck # Correct previous command
      bc # Command line calculator

      # SDKs and miscellaneous packages
      nuget-to-nix # Convert a NuGet packages directory to a lockfile for buildDotnetModule
      omnisharp-roslyn # C# language server
      mono # .NET Framework for Linux and macOS
      bun # Better JavaScript runtime
      nodejs_21 # Node.js version 21
      nil # Nix language server
    ];
    variables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "true"; # Opt out of .NET CLI telemetry
      DOTNET_ROOT = "/run/current-system/sw/share/dotnet"; # .NET SDK path
    };
  };
}
