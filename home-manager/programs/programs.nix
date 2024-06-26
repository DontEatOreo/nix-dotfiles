# Any program.something that isn't too long goes here!
_: {
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
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
  programs.gh.enable = true;
  progrmas.gitui.enable = true;
  programs.thefuck = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
}
