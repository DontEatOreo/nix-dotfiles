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
        ghostscript # Interpreter for PostScript and PDF (Convert PDF to Image)
        imagemagick # Image Manipulation

        # Other
        eza # Bettter LS
        neofetch # Show System Info
        tldr # Most Common used commands for CLI tool
        tree
        wget
        ;
      dis = inputs.dis.packages.${pkgs.system}.default;
    };
    variables = {
      EDITOR = "nvim";
    };
  };
}
