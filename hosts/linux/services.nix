{
  pkgs,
  pkgsUnstable,
  config,
  ...
}:
{
  services = {
    xserver.enable = true;
    tailscale.enable = true;
    tailscale.package = pkgsUnstable.tailscale;
  };
}
