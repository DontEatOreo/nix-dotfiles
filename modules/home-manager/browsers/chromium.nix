{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.hm.chromium.enable = mkEnableOption "Enable Chromium";

  config = mkIf config.hm.chromium.enable {
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
