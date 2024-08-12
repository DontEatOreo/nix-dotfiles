{ pkgs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        # Essential Tools
        alacritty # GPU Terminal
        xclip # Clipboard for NVIM
        xmousepasteblock # Disable Middle Click

        # Communication Tools
        telegram-desktop

        # Password Management Tools
        _1password-gui
        keepassxc

        # Multimedia Tools
        pavucontrol
        ;
    };
  };
}
