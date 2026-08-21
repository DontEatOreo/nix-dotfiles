{
  description = "Development-only inputs for the dotfiles flake partition";

  inputs = {
    git-hooks-nix = {
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "";
      };
      url = "github:cachix/git-hooks.nix";
    };
  };

  outputs = _: { };
}
