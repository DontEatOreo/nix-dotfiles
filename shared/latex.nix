{pkgs, ...}: {
  environment = {
    systemPackages = with pkgs; [
      # LaTeX Related
      texlive.combined.scheme-full
      pandoc # Convert Documents
    ];
  };
}
