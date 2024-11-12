{ pkgs, ... }:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      htop-vim
      nix-tree
      ;
  };
}
