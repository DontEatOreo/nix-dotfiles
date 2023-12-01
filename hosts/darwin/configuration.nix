_: {
  imports =
    []
    ++ (import ./users/anon)
    ++ (import ../../shared);

  services.nix-daemon.enable = true;
}
