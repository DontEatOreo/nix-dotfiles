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
      {
        shared = {
          nix.enable = true;
          nixpkgs = {
            enable = true;
            cudaSupport = true;
          };
        };
      }
      ../../modules/de
      {
        nixOS = {
          gnome.enable = true;
        };
      }

      inputs.catppuccin.nixosModules.catppuccin
      {
        catppuccin = {
          enable = true;
          flavor = "frappe";
          accent = "teal";
        };
      }
      inputs.nur.modules.nixos.default
      inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h
      inputs.sops-nix.nixosModules.sops
      {
        sops = {
          age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
          defaultSopsFile = ../../secrets/secrets.yaml;
        };
      }

      inputs.xremap-flake.nixosModules.default
    ];
  };
}
