{pkgs, ...}: let
  # Python packages
  python-packages = ps:
    with ps; [
      # Mathematical computations
      numba # Speed up Python computations
      numpy
      sympy # Symbolic mathematics
      scipy # Scientific computations

      # Data analysis
      pandas
      matplotlib # Data visualization
      seaborn # Statistical data visualization
      scikit-learn # Machine learning library

      # Image processing
      pillow # Image processing

      # Web development
      requests # HTTP requests
      flask # Web framework
      django # Web framework
      sqlalchemy # SQL toolkit and ORM
      beautifulsoup4 # Web scraping

      # Text processing
      ansi2image # Convert ANSI codes to images
      pygments # Syntax highlighting
      tiktoken # Fast tokenizer from OpenAI

      # GUI development
      tkinter

      # Utilities
      tqdm # Progress bars
      more-itertools # Additional functions for working with iterables

      # Testing
      pytest # Testing framework

      # Code formatting
      black # Code formatter

      # Static typing
      mypy # Static type checker
    ];

  # .NET SDKs
  dotnetSdks = with pkgs; [
    dotnet-sdk # Latest LTS release (6.0)
    dotnet-sdk_7 # .NET SDK version 7
    dotnet-sdk_8 # .NET SDK version 8
  ];
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
      rnix-lsp # Nix LSP
    ];
    variables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "true"; # Opt out of .NET CLI telemetry
      DOTNET_ROOT = "/run/current-system/sw/share/dotnet"; # .NET SDK path
    };
  };
}
