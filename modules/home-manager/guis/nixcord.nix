{
  inputs,
  lib,
  config,
  ...
}:
{
  imports = [ inputs.nixcord.homeManagerModules.nixcord ];

  options.hm.nixcord = {
    enable = lib.mkEnableOption "Enable NixCord";
    theme = {
      dark = {
        flavor = lib.mkOption {
          type = lib.types.str;
          default = config.catppuccin.flavor;
          description = "Catppuccin flavor for dark mode";
        };
        accent = lib.mkOption {
          type = lib.types.str;
          default = config.catppuccin.accent;
          description = "Accent color for dark mode";
        };
      };
      light = {
        flavor = lib.mkOption {
          type = lib.types.str;
          default = "latte";
          description = "Catppuccin flavor for light mode";
        };
        accent = lib.mkOption {
          type = lib.types.str;
          default = config.catppuccin.accent;
          description = "Accent color for light mode";
        };
      };
    };
  };

  config = lib.mkIf config.hm.nixcord.enable {
    programs.nixcord = {
      enable = true;
      vesktop.enable = true;
      quickCss =
        ''
          /* ----- CATPPUCCIN THEME ----- */
          @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.hm.nixcord.theme.dark.flavor}-${config.hm.nixcord.theme.dark.accent}.theme.css")
          (prefers-color-scheme: dark);
          @import url("https://catppuccin.github.io/discord/dist/catppuccin-${config.hm.nixcord.theme.light.flavor}-${config.hm.nixcord.theme.light.accent}.theme.css")
          (prefers-color-scheme: light);
        ''
        + builtins.readFile ../config/quickCSS.css;
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
          friendInvites.enable = true;
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
          messageLatency.enable = true;
          messageLinkEmbeds.enable = true;
          messageLogger = {
            enable = true;
            collapseDeleted = true;
            ignoreSelf = true;
            ignoreBots = true;
          };
          messageTags.enable = true;
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
          noScreensharePreview.enable = true;
          noTypingAnimation.enable = true;
          noUnblockToJump.enable = true;
          onePingPerDM.enable = true;
          pauseInvitesForever.enable = true;
          permissionsViewer.enable = true;
          pictureInPicture.enable = true;
          pinDMs.enable = true;
          platformIndicators.enable = true;
          previewMessage.enable = true;
          quickMention.enable = true;
          reactErrorDecoder.enable = true;
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
          voiceDownload.enable = true;
          voiceMessages.enable = true;
          volumeBooster.enable = true;
          webScreenShareFixes.enable = true;
          youtubeAdblock.enable = true;
        };
      };
    };
  };
}
