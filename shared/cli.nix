{pkgs, ...}: {
  environment = {
    systemPackages = builtins.attrValues {
      inherit
        (pkgs)
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
        vhs
        coreutils # GNU CoreUtils
        progress # Show progress of CoreUtils
        ;
    };
    variables = {
      EDITOR = "nvim";
    };
  };
}
