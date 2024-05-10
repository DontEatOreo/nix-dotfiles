{pkgs, ...}: {
  nix = {
    package = pkgs.nix;
    # Garbage Collection
    gc = {
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };
    # auto-optimise-store = true
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings = {
      # Trust Devenv Shell
      trusted-substituters = [
        "https://devenv.cachix.org"
      ];
      trusted-public-keys = [
        "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      ];
    };
  };
}
