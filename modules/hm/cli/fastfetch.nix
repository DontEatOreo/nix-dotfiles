{ lib, config, ... }:
{
  options.hm.fastfetch.enable = lib.mkEnableOption "Fastfetch";

  config = lib.mkIf config.hm.fastfetch.enable {
    programs.fastfetch.enable = true;
    programs.fastfetch.settings = {
      display = {
        size = {
          maxPrefix = "MB";
          ndigits = 0;
        };
      };
      modules = [
        "title"
        "separator"
        "os"
        "host"
        {
          format = "{release}";
          type = "kernel";
        }
        "uptime"
        "packages"
        "shell"
        {
          compactType = "original";
          key = "Resolution";
          type = "display";
        }
        "de"
        "wm"
        "wmtheme"
        "theme"
        "icons"
        "terminal"
        {
          format = "{/name}{-}{/}{name}{?size} {size}{?}";
          type = "terminalfont";
        }
        "cpu"
        {
          key = "GPU";
          type = "gpu";
        }
        {
          format = "{} / {}";
          type = "memory";
        }
        "break"
        "colors"
      ];
    };
  };
}
