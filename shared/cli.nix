{pkgs, ...}: let
  ffmpeg-h264-patched = pkgs.ffmpeg.override {
    x264 = pkgs.x264.overrideAttrs (old: {
      postPatch =
        old.postPatch
        + pkgs.lib.optionalString (pkgs.stdenv.isDarwin) ''
          substituteInPlace Makefile --replace '$(if $(STRIP), $(STRIP) -x $@)' '$(if $(STRIP), $(STRIP) -S $@)'
        '';
    });
  };
in {
  environment = {
    systemPackages = with pkgs; [
      # CLI Tools
      # Video Related
      ffmpeg-h264-patched
      (yt-dlp.override {ffmpeg = ffmpeg-h264-patched;}) # Video Downloader

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
      (vhs.override { ffmpeg = ffmpeg-h264-patched; })
      coreutils # GNU CoreUtils
      progress # Show progress of CoreUtils
    ];
    variables = {
      EDITOR = "nvim";
    };
  };
}
