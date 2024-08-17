_: {
  programs = {
    direnv = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
    gh.enable = true;
    git = {
      enable = true;
      delta.enable = true;
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
    gitui.enable = true;
    thefuck = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };
  };
}
