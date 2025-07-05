{
  inputs,
  pkgs,
  config,
  ...
}:
{
  services = {
    xserver.enable = true;
    tailscale.enable = true;
    tailscale.package =
      inputs.nixpkgs-unstable.legacyPackages.${config.nixpkgs.hostPlatform.system}.tailscale;
  };
}
