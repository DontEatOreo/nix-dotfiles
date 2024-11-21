{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      btop
      ncdu
      nix-tree
      ;
  };
}
