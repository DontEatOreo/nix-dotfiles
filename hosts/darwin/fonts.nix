{ pkgs, ... }:
{
  fonts = {
    packages = builtins.attrValues {
      inherit (pkgs)
        # Dev
        fira-code
        fira-code-symbols
        monaspace
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        ;
      nerdfonts = pkgs.nerdfonts.override {
        fonts = [
          "DroidSansMono"
          "FiraCode"
          "Monaspace"
          "Noto"
        ];
      };
    };
  };
}
