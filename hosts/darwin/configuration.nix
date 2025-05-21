{ pkgs, ... }:
{
  system.primaryUser = "anon";

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  users.users.anon = {
    name = "anon";
    home = "/Users/anon";
    shell = pkgs.zsh;
  };
}
