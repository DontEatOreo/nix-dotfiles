{ inputs, pkgs, ... }:
{
  imports = [ inputs.sops-nix.darwinModules.sops ];

  system.primaryUser = "anon";

  nixpkgs.hostPlatform.system = "aarch64-darwin";

  users.users.anon = {
    name = "anon";
    home = "/Users/anon";
    shell = pkgs.zsh;
  };

  sops = {
    age.keyFile = "/Users/anon/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets.github_ssh = { };
    secrets.lenovo_legion_5_15arh05h_ssh = { };
  };

}
