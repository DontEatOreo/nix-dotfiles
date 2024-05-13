{ pkgs, ... }:
{
  environment = {
    systemPackages = builtins.attrValues {
      text-live-full = pkgs.texlive.combined.scheme-full;
      inherit (pkgs) pandoc;
    };
  };
}
