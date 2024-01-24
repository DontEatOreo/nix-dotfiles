_: {
  programs.git = {
    enable = true;
    ignores = [
      ".DS_Store"
      "Thumbs.db"
      "*.DS_Store"
      "*.swp"
    ];
    userName = "DontEatOreo";
    userEmail = "57304299+DontEatOreo@users.noreply.github.com";
    signing = {
      signByDefault = true;
      key = "0DB5361BEEE530AB";
    };
  };
}
