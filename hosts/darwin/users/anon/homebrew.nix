{
  homebrew = {
    enable = true;
    caskArgs = {
      no_quarantine = true;
    };
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "uninstall";
    };
    taps = [
      "dahlia/jetbrains-eap" # https://github.com/dahlia/homebrew-jetbrains-eap
      "homebrew/cask-fonts"
    ];
    brews = [
      "smartmontools" # Check System Health
    ];
    casks = [
      # Browsers
      "microsoft-edge"
      "brave-browser"
      "firefox"

      # Messengers
      "discord"
      "telegram"

      # Quality of Life
      "hiddenbar" # Hide status bar items
      "stats" # System Stats
      "soundsource" # Proper Sound Mixer
      "alt-tab" # Proper Alt Tab
      "rectangle" # Snap Windows
      "itsycal" # Better Calendar

      # Other
      "warp" # Modern Terminal
      "postman" # Create HTTP requests
      "obsidian" # Note taking
      "iina" # Best video player
      "transmission" # Torrent client
      "thunderbird" # Email client
      "font-monaspace" # Github Fonts

      # Dev
      "rider-eap"
    ];
  };
}
