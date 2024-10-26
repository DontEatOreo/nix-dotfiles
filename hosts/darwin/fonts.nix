{ pkgs, ... }:
{
  fonts = {
    packages = builtins.attrValues {
      inherit (pkgs)
        # I guess gotta have em'
        crimson
        crimson-pro
        ibm-plex
        inter
        open-sans
        paratype-pt-sans
        roboto
        source-sans
        source-sans-pro

        # Obviously NOTO DUHH!!!
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji

        # Collection of "Comic" fonts
        comic-mono
        comic-neue
        comic-relief

        # JP fonts
        plemoljp
        plemoljp-hs
        plemoljp-nf
        source-han-sans
        source-han-sans-vf-otf
        source-han-sans-vf-ttf

        # Dev
        monaspace
        ;
      nerdfonts = pkgs.nerdfonts.override {
        fonts = [
          "Noto"
          "Monaspace"
          "DroidSansMono"
          "FiraCode"
        ];
      };
    };
  };
}
