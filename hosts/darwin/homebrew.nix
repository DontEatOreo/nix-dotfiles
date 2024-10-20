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
    brews = [
      "smartmontools" # Check System Health
    ];
    casks = [
      # Browsers
      "microsoft-edge"
      "brave-browser"
      "zen-browser"
      "mullvad-browser"

      # Messengers
      "telegram"
      "element"

      # Quality of Life
      "hiddenbar" # Hide status bar items
      "stats" # System Stats
      "alt-tab" # Proper Alt Tab
      "lasso" # Window Manager
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
    ];
  };
}
