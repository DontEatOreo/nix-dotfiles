{ pkgs, ... }:
let
  # krisp-patcher ~/.config/discord/0.0.72/modules/discord_krisp/discord_krisp.node
  krisp-patcher =
    pkgs.writers.writePython3Bin "krisp-patcher"
      {
        libraries = with pkgs.python3Packages; [
          capstone
          pyelftools
        ];
        flakeIgnore = [
          "E501" # line too long (82 > 79 characters)
          "F403" # 'from module import *' used; unable to detect undefined names
          "F405" # name may be undefined, or defined from star imports: module
        ];
      }
      (
        builtins.readFile (
          pkgs.fetchurl {
            url = "https://raw.githubusercontent.com/sersorrel/sys/afc85e6b249e5cd86a7bcf001b544019091b928c/hm/discord/krisp-patcher.py";
            sha256 = "sha256-h8Jjd9ZQBjtO3xbnYuxUsDctGEMFUB5hzR/QOQ71j/E=";
          }
        )
      );
in
{
  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        # Communication Tools
        telegram-desktop

        # Password Management Tools
        _1password-gui
        keepassxc

        # Multimedia Tools
        pavucontrol
        ;
      inherit krisp-patcher;
    };
  };
}
