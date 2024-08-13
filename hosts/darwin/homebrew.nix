_: {
  homebrew = {
    enable = true;
    caskArgs = {
      no_quarantine = true;
    };
    onActivation = {
      cleanup = "uninstall";
    };
    taps = [
      # "dahlia/jetbrains-eap" # https://github.com/dahlia/homebrew-jetbrains-eap
      "homebrew/cask-fonts"
    ];
    masApps = {
      Xcode = 497799835;
    };
    brews = [
      "smartmontools" # Check System Health
    ];
    casks = [
      # Browsers
      "microsoft-edge"
      "brave-browser"
      "firefox"
      "mullvad-browser"

      # Messengers
      "discord"
      "telegram"
      "element"

      # Quality of Life
      "hiddenbar" # Hide status bar items
      "stats" # System Stats
      "alt-tab" # Proper Alt Tab
      "rectangle" # Snap Windows
      "itsycal" # Better Calendar

      # Other
      "obsidian" # Note taking
      "iina" # Best video player
      "transmission" # Torrent client
      "thunderbird" # Email client
      "mullvadvpn" # VPN

      # Dev
      "rider"
      "warp" # Modern Terminal
      "postman" # Create HTTP requests
      "font-monaspace" # Github Fonts
    ];
  };
}
