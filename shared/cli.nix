{ pkgs, inputs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues {
      inherit (pkgs)
        # Video Related
        ffmpeg_7-full
        yt-dlp # Video Downloader

        # Images Related
        gallery-dl # Image Downloader
        imagemagick # Image Manipulation
        ghostscript # Interpreter for PostScript and PDF (Convert PDF to Image)

        # Other
        eza # Bettter LS
        tldr # Most Common used commands for CLI tool
        tree
        neofetch # Show System Info
        wget
        ;
      dis = inputs.dis.packages.${pkgs.system}.default;
    };
    variables = {
      EDITOR = "nvim";
    };
  };
}
