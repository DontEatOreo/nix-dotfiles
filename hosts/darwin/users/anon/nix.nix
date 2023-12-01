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
  };
}
