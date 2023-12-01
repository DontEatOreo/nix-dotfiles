{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      # CLI Tools
      # Video Related
      ffmpeg_6-full
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
      nixpkgs-fmt # Format Nix Files
      wget
      alejandra # Format Nix Files
      direnv
      gnupg
      coreutils # GNU CoreUtils
      progress # Show progress of CoreUtils
    ];
    variables = {
      EDITOR = "nvim";
    };
  };
}
