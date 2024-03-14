{pkgs, ...}: let
  python-packages = import ./pythonPackages.nix;
  dotnetSdks = import ./dotnetSdks.nix {inherit pkgs;};
in {
  environment = {
    systemPackages = with pkgs; [
      # Git and GitHub related packages
      gh # GitHub CLI
      git # Git VCS
      gitty # Information about Git repositories
      gitui # Terminal UI for Git
      gitflow # Git branching model
      github-copilot-cli # GitHub Copilot CLI

      # Terminal related packages
      colordiff # Colorize diff output
      thefuck # Correct previous command
      bc # Command line calculator

      # SDKs and miscellaneous packages
      (python311.withPackages python-packages) # Python 3.11 with specified packages
      (dotnetCorePackages.combinePackages dotnetSdks) # Combined .NET SDKs
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
