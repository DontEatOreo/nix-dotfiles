{
  description = "NixOS-only inputs for the dotfiles flake partition";

  inputs = {
    # This partition only consumes browser's NixOS module. Keep its other
    # module-system inputs out of the partition lock graph.
    browser = {
      inputs = {
        home-manager.follows = "";
        nix-darwin.follows = "";
        nixpkgs.follows = "";
      };
      url = "github:4evy/browser";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    sops-nix.inputs.nixpkgs.follows = "";
    sops-nix.url = "github:Mic92/sops-nix";

    vicinae.url = "github:vicinaehq/vicinae";
  };

  outputs = _: { };
}
