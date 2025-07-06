{
  inputs,
  lib,
  config,
  osConfig,
  ...
}:
{
  imports = [
    ./languages.nix
    ./settings.nix
  ];

  options.hm.helix.enable = lib.mkEnableOption "Helix";

  config = lib.mkIf config.hm.helix.enable {
    programs.helix.enable = true;
    programs.helix.package = (
      inputs.helix-editor.packages.${osConfig.nixpkgs.hostPlatform.system}.helix.overrideAttrs {
        doCheck = false;
      }
    );
    programs.helix.defaultEditor = true;
  };
}
