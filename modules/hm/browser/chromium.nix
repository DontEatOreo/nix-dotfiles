{
  pkgs,
  lib,
  config,
  osConfig,
  ...
}:
let
  inherit (osConfig.nixpkgs.hostPlatform) isLinux;
in
{
  options.hm.chromium.enable = lib.mkEnableOption "Chromium";

  config = lib.mkIf config.hm.chromium.enable {
    assertions = [
      {
        assertion = isLinux;
        message = "Declerative Firefox is only available on Linux";
      }
    ];
    programs.chromium = {
      enable = true;
      package = pkgs.brave;
      dictionaries = [ pkgs.hunspellDictsChromium.en_US ];
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # Ublock Origin
        { id = "mnjggcdmjocbbbhaepdhchncahnbgone"; } # Sponsor Block
        { id = "enamippconapkdmgfgjchkhakpfinmaj"; } # Dearrow
        { id = "gebbhagfogifgggkldgodflihgfeippi"; } # Return YT Dislikes
        { id = "pobhoodpcipjmedfenaigbeloiidbflp"; } # Minimal Twitta Theme
      ];
    };
  };
}
