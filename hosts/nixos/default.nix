{ inputs, ... }:
let
  system = "x86_64-linux";
  username = "nyx";
  hostname = "nyx";
in
{
  ${username} = inputs.nixpkgs.lib.nixosSystem {
    inherit system;
    specialArgs = {
      inherit
        inputs
        system
        username
        hostname
        ;
    };
    modules = [
      ./configuration.nix
      ../../modules/common
      ../../modules/de

      inputs.nur.nixosModules.nur
      inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h
      inputs.lix-module.nixosModules.default
      inputs.sops-nix.nixosModules.sops
      {
        sops = {
          age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
          defaultSopsFile = ../../secrets/secrets.yaml;
        };
      }

      # Home Manger
      inputs.home-manager.nixosModules.home-manager
      ./home.nix

      inputs.xremap-flake.nixosModules.default
    ];
  };
}
