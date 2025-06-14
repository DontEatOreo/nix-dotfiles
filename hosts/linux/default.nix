{ inputs, ... }:
{
  lenovo-legion = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./configuration.nix
      ../../modules/common
      ../../modules/nixos
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
          accent = "blue";
        };
      }
      inputs.nur.modules.nixos.default
      inputs.nixos-hardware.nixosModules.lenovo-legion-15arh05h
      inputs.sops-nix.nixosModules.sops
      {
        sops = {
          age.keyFile = "/home/nyx/.config/sops/age/keys.txt";
          defaultSopsFile = ../../secrets/secrets.yaml;
          secrets.github_ssh = { };
          secrets.lenovo_legion_5_15arh05h_ssh = { };
        };
      }
    ];
  };
}
