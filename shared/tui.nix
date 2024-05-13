{ pkgs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues { inherit (pkgs) htop-vim ncdu nix-tree; };
  };
}
