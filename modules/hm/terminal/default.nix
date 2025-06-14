{
  pkgs,
  lib,
  osConfig,
  ...
}:
{
  imports = [
    ./bash.nix
    ./ghostty.nix
    ./nushell.nix
    ./starship.nix
  ] ++ lib.optionals osConfig.nixpkgs.hostPlatform.isLinux [ ./zsh.nix ];
}
