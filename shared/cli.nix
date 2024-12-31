{ pkgs, inputs, ... }:
{
  environment = {
    systemPackages =
      builtins.attrValues {
        inherit (pkgs)
          # Video Related
          ffmpeg_7-full
          yt-dlp # Video Downloader

          # Images Related
          gallery-dl # Image Downloader
          ghostscript # Interpreter for PostScript and PDF (Convert PDF to Image)
          imagemagick # Image Manipulation

          # Other
          tldr # Most Common used commands for CLI tool
          tree
          wget
          ;
        dis = inputs.dis.packages.${pkgs.system}.default;
      }
      # Rust implementation of GNU tools
      ++ builtins.attrValues {
        inherit (pkgs)
          bat # cat
          dust # du
          eza # ls
          fd # find
          ripgrep-all # grep
          sd # sed
          zoxide # cd
          ;
      };
    variables = {
      EDITOR = "nvim";
    };
  };
}
