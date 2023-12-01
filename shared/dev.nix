{pkgs, ...}: let
  python-packages = ps:
    with ps; [
      numba # Speed up Python
      numpy # Math
      pandas # Data Analysis
      requests # HTTP Requests
      matplotlib # Plotting
      flask # Web Framework
      django # Web Framework
      beautifulsoup4 # Web Scraping
      ansi2image # Convert ANSI to Image
      pygments # Syntax Highlighting
      tkinter # GUI Stuff
      sympy # Symbolic Math
      tqdm # Progress Bar
      more-itertools # More Itertools
      tiktoken # Fast Tokenizer from OpenAI

      # AI related
      keras # Deep Learning for Theano and TensorFlow
      torch # Tensors and Dynamic neural networks in Python with strong GPU acceleration
      torchvision # Deep Learning
    ];
  dotnetSdks = with pkgs; [
    dotnet-sdk # Last LTS Release (6.0)
    dotnet-sdk_7
    dotnet-sdk_8
  ];
in {
  environment = {
    systemPackages = with pkgs; [
      # Dev
      # Git and GitHub Related
      gh
      git
      gitty # Info about repos
      gitui
      gitflow
      github-copilot-cli

      # Terminal Related
      colordiff
      thefuck # Correct last command
      bc # Calculator

      # SDK & Misc
      (python311.withPackages python-packages)
      (dotnetCorePackages.combinePackages dotnetSdks)
      nuget-to-nix # Convert a nuget packages directory to a lockfile for buildDotnetModule
      omnisharp-roslyn # C# Lang Server
      mono # .NET Framework for Linux & macOS
      bun # Better JS Runtime
      nodejs_21
      nil # Nix Lang Server
      rnix-lsp # Nix LSP
    ];
    variables = {
      DOTNET_CLI_TELEMETRY_OPTOUT = "true";
      DOTNET_ROOT = "/run/current-system/sw/share/dotnet"; # .NET SDK Path
    };
  };
}
