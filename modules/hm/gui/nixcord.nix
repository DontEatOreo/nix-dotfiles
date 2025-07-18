{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nixcord.homeModules.nixcord ];

  options.hm.nixcord.enable = lib.mkEnableOption "NixCord";

  config = lib.mkIf config.hm.nixcord.enable {
    programs.nixcord = {
      enable = true;
      # discord.vencord.unstable = true;
      quickCss = ''
        /* ----- CATPPUCCIN THEME ----- */
        @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.catppuccin.flavor}-${config.catppuccin.accent}.theme.css")
        (prefers-color-scheme: dark);
        @import url("https://catppuccin.github.io/discord/dist/catppuccin-latte-${config.catppuccin.accent}.theme.css")
        (prefers-color-scheme: light);
      '';
      config = {
        useQuickCss = true;
        plugins = {
          alwaysExpandRoles.enable = true;
          betterGifPicker.enable = true;
          betterNotesBox.enable = true;
          betterSessions.enable = true;
          betterSettings.enable = true;
          betterUploadButton.enable = true;
          biggerStreamPreview.enable = true;
          blurNSFW.enable = true;
          callTimer = {
            enable = true;
            format = "human";
          };
          clearURLs.enable = true;
          colorSighted.enable = true;
          consoleJanitor.disableNoisyLoggers = true;
          consoleJanitor.enable = true;
          crashHandler.enable = true;
          dearrow.enable = true;
          disableCallIdle.enable = true;
          dontRoundMyTimestamps.enable = true;
          favoriteEmojiFirst.enable = true;
          fixCodeblockGap.enable = true;
          fixSpotifyEmbeds.enable = true;
          fixYoutubeEmbeds.enable = true;
          forceOwnerCrown.enable = true;
          friendsSince.enable = true;
          fullSearchContext.enable = true;
          gifPaste.enable = true;
          greetStickerPicker.enable = true;
          hideAttachments.enable = true;
          ignoreActivities = {
            enable = true;
            ignorePlaying = true;
            ignoreListening = true;
            ignoreWatching = true;
            ignoreCompeting = true;
          };
          imageZoom.enable = true;
          implicitRelationships.enable = true;
          memberCount.enable = true;
          messageLinkEmbeds.enable = true;
          messageLogger = {
            enable = true;
            collapseDeleted = true;
            ignoreSelf = true;
            ignoreBots = true;
          };
          moreUserTags.enable = true;
          mutualGroupDMs.enable = true;
          newGuildSettings.enable = true;
          noBlockedMessages.enable = true;
          noDevtoolsWarning.enable = true;
          noF1.enable = true;
          noMaskedUrlPaste.enable = true;
          noMosaic.enable = true;
          noPendingCount.enable = true;
          noProfileThemes.enable = true;
          normalizeMessageLinks.enable = true;
          noRPC.enable = true;
          noTypingAnimation.enable = true;
          noUnblockToJump.enable = true;
          onePingPerDM.enable = true;
          pauseInvitesForever.enable = true;
          permissionsViewer.enable = true;
          pictureInPicture.enable = true;
          platformIndicators.enable = true;
          previewMessage.enable = true;
          readAllNotificationsButton.enable = true;
          relationshipNotifier.enable = true;
          replyTimestamp.enable = true;
          revealAllSpoilers.enable = true;
          reverseImageSearch.enable = true;
          roleColorEverywhere.enable = true;
          serverInfo.enable = true;
          serverListIndicators.enable = true;
          shikiCodeblocks.enable = true;
          showConnections.enable = true;
          showHiddenThings.enable = true;
          showMeYourName.enable = true;
          showMeYourName.mode = "nick-user";
          showTimeoutDuration.enable = true;
          silentTyping.enable = true;
          startupTimings.enable = true;
          streamerModeOnStream.enable = true;
          superReactionTweaks.enable = true;
          textReplace.enable = true;
          textReplace.regexRules = [
            {
              find = "https?:\\/\\/(www\\.)?instagram\\.com\\/[^\\/]+\\/(p|reel)\\/([A-Za-z0-9-_]+)\\/?";
              replace = "https://g.ddinstagram.com/$2/$3";
            }
            {
              find = "https:\\/\\/x\\.com\\/([^\\/]+\\/status\\/[0-9]+)";
              replace = "https://vxtwitter.com/$1";
            }
            {
              find = "https:\\/\\/twitter\\.com\\/([^\\/]+\\/status\\/[0-9]+)";
              replace = "https://vxtwitter.com/$1";
            }
            {
              find = "https:\\/\\/(www\\.)?tiktok\\.com\\/(.*)";
              replace = "https://vxtiktok.com/$2";
            }
            {
              find = "https:\\/\\/(www\\.|old\\.)?reddit\\.com\\/(r\\/[a-zA-Z0-9_]+\\/comments\\/[a-zA-Z0-9_]+\\/[^\\s]*)";
              replace = "https://vxreddit.com/$2";
            }
            {
              find = "https:\\/\\/(www\\.)?pixiv\\.net\\/(.*)";
              replace = "https://phixiv.net/$2";
            }
            {
              find = "https:\\/\\/(?:www\\.|m\\.)?twitch\\.tv\\/twitch\\/clip\\/(.*)";
              replace = "https://clips.fxtwitch.tv/$1";
            }
            {
              find = "https:\\/\\/(?:www\\.)?youtube\\.com\\/(?:watch\\?v=|shorts\\/)([a-zA-Z0-9_-]+)";
              replace = "https://youtu.be/$1";
            }
          ];
          themeAttributes.enable = true;
          translate.enable = true;
          typingIndicator.enable = true;
          typingTweaks.enable = true;
          unindent.enable = true;
          unlockedAvatarZoom.enable = true;
          userVoiceShow.enable = true;
          validReply.enable = true;
          validUser.enable = true;
          vencordToolbox.enable = true;
          viewIcons.enable = true;
          viewRaw.enable = true;
          voiceChatDoubleClick.enable = true;
          voiceMessages.enable = true;
          volumeBooster.enable = true;
          webScreenShareFixes.enable = true;
          youtubeAdblock.enable = true;
        };
      };
    };
  };
}
