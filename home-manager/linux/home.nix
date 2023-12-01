{pkgs, ...}: {
  imports =
    []
    ++ (import ../programs)
    ++ (import ../programs/linux);
  home = {
    stateVersion = "24.05";
    packages = with pkgs; [
      alacritty # GPU Terminal
      xclip # Clipboard for NVIM

      discord
      telegram-desktop
      _1password-gui
    ];
  };
}
