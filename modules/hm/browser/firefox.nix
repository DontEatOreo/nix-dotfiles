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
  options.hm.firefox.enable = lib.mkEnableOption "Declerative Firefox";

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
        extensions.packages = builtins.attrValues {
          inherit (pkgs.nur.repos.rycee.firefox-addons)
            ublock-origin # Ad Blocker
            tree-style-tab
            sponsorblock # YouTube Sponsor Skipper
            dearrow # YouTube Clickbait Remover
            return-youtube-dislikes
            violentmonkey # Browser Scripts
            ;
        };
        settings = {
          "media.ffmpeg.vaapi.enabled" = true;
          "media.gpu-process.enabled" = true;
        };
        search = {
          force = true;
          default = "google";
          privateDefault = "google";
          order = [
            "GitHub"
            "google"
            "Kagi"
            "Nix Packages"
            "youtube"
          ];
          engines = {
            GitHub = {
              urls = [
                {
                  template = "https://github.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "https://github.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@gh" ];
            };
            google.metaData.alias = "@g"; # builtin engines only support specifying one additional alias
            Kagi = {
              urls = [
                {
                  template = "https://kagi.com/search";
                  params = [
                    {
                      name = "q";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "https://assets.kagi.com/v2/apple-touch-icon.png";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@k" ];
            };
            "Nix Packages" = {
              urls = [
                {
                  template = "https://search.nixos.org/packages";
                  params = [
                    {
                      name = "channel";
                      value = "unstable";
                    }
                    {
                      name = "query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            youtube = {
              urls = [
                {
                  template = "https://www.youtube.com/results";
                  params = [
                    {
                      name = "search_query";
                      value = "{searchTerms}";
                    }
                  ];
                }
              ];
              icon = "https://youtube.com/favicon.ico";
              updateInterval = 24 * 60 * 60 * 1000;
              definedAliases = [ "@yt" ];
            };
          };
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
