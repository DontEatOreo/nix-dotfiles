{
  pkgs,
  lib,
  config,
  system,
  ...
}:
let
  isLinux = builtins.match ".*linux.*" system != null;
in
{
  options.hm.firefox.enable = lib.mkEnableOption "Enable Declerative Firefox";

  config = lib.mkIf config.hm.firefox.enable {
    assertions = [
      {
        assertion = isLinux;
        message = "Declerative Firefox is only available on Linux";
      }
    ];
    programs.firefox = {
      enable = true;
      profiles.main = {
        isDefault = true;
        extensions = builtins.attrValues {
          inherit (pkgs.nur.repos.rycee.firefox-addons)
            ublock-origin # Ad Blocker
            tree-style-tab
            sponsorblock # YouTube Sponsor Skipper
            dearrow # YouTube Clickbait Remover
            return-youtube-dislikes
            violentmonkey # Browser Scripts
            ;
        };
      };
      policies = {
        DisableTelemetry = true;
        OfferToSaveLogins = false;
        OfferToSaveLoginsDefault = false;
        PasswordManagerEnabled = false;
        NoDefaultBookmarks = true;
        DisableFirefoxAccounts = true;
        DisableFeedbackCommands = true;
        DisableFirefoxStudies = true;
        DisableMasterPasswordCreation = true;
        DisablePocket = true;
        DisableSetDesktopBackground = true;
      };
    };
  };
}
