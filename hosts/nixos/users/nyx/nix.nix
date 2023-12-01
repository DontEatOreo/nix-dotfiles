{
  inputs,
  lib,
  ...
}: {
  nix = {
    # Add each flake input as a registery, to make nix3 commands consistent with flake.nix
    registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = ["/etc/nix/path"];
    settings = {
      # Enable flakes and new 'nix3' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };
}
