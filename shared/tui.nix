{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      # TUI
      htop-vim # HTOP with Vim Keybindings
      ncdu # Find Biggest files
    ];
  };
}
