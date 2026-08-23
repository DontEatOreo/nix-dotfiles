{ lib, parseRules }:
let
  inherit (lib.attrsets) mapAttrs' nameValuePair;

  toUpper =
    string:
    lib.strings.concatStrings [
      (lib.strings.toUpper (builtins.substring 0 1 string))
      (builtins.substring 1 (builtins.stringLength string) string)
    ];

  pluginJsonName = name: parseRules.pluginRenames.${name} or (toUpper name);

  pluginToJson =
    plugin:
    (removeAttrs plugin [ "enable" ])
    // {
      enabled = plugin.enable or true;
    };

  nixcordConfig = {
    useQuickCss = true;
    plugins = {
      alwaysExpandRoles.enable = true;
      betterGifPicker.enable = true;
      betterSettings.enable = true;
      betterUploadButton.enable = true;
      biggerStreamPreview.enable = true;
      callTimer = {
        enable = true;
        format = "human";
      };
      clearUrls.enable = true;
      crashHandler.enable = true;
      disableCallIdle.enable = true;
      dontRoundMyTimestamps.enable = true;
      equicordHelper.enable = true;
      favoriteEmojiFirst.enable = true;
      fixCodeblockGap.enable = true;
      fixImagesQuality.enable = true;
      fixYoutubeEmbeds.enable = true;
      forceOwnerCrown.enable = true;
      fullSearchContext.enable = true;
      fullVcpfp.enable = true;
      gifPaste.enable = true;
      greetStickerPicker.enable = true;
      hideChatButtons.enable = true;
      hideMedia.enable = true;
      hideServers.enable = true;
      homeTyping.enable = true;
      ignoreActivities = {
        enable = true;
        ignoreCompeting = true;
        ignoreListening = true;
        ignorePlaying = true;
        ignoreWatching = true;
      };
      imageFilename.enable = true;
      implicitRelationships.enable = true;
      lastActive.enable = true;
      limitlessScreenshare.enable = true;
      memberCount.enable = true;
      mentionAvatars.enable = true;
      messageLogger = {
        enable = true;
        collapseDeleted = true;
        ignoreBots = true;
        ignoreSelf = true;
      };
      messageLoggerEnhanced.enable = true;
      mutualGroupDms.enable = true;
      newGuildSettings.enable = true;
      newPluginsManager.enable = true;
      noBlockedMessages.enable = true;
      noDevtoolsWarning.enable = true;
      noF1.enable = true;
      noMaskedUrlPaste.enable = true;
      noMosaic.enable = true;
      noPendingCount.enable = true;
      noProfileThemes.enable = true;
      noTypingAnimation.enable = true;
      noUnblockToJump.enable = true;
      onePingPerDm.enable = true;
      pauseInvitesForever.enable = true;
      pictureInPicture.enable = true;
      platformIndicators.enable = true;
      previewMessage.enable = true;
      questify = {
        enable = true;
        migrationVersion = 1;
        disableQuestsEverything = false;
        questButtonDisplay = "always";
        disableMembersListPromo = true;
        disableFriendsListPromo = true;
        disableRelocationNotices = true;
        disableSponsoredBanner = false;
        disableOrbsAndQuestsBadges = false;
        disableAccountPanelPromo = true;
        autoCompleteQuestTypes = {
          PLAY_ON_DESKTOP = true;
          PLAY_ON_XBOX = true;
          PLAY_ON_PLAYSTATION = true;
          PLAY_ACTIVITY = true;
          WATCH_VIDEO = true;
          WATCH_VIDEO_ON_MOBILE = true;
          ACHIEVEMENT_IN_ACTIVITY = true;
        };
        preventVideoQuestsPausing = true;
        disableAccountPanelQuestProgress = false;
        acknowledgedNotices = {
          "quest-ban-warning-2026-08-07" = true;
        };
        allowChangingDangerousSettings = true;
        isOnQuestsPage = true;
        newExcludedQuestAlertSound = null;
        newQuestAlertSound = "discodo";
        questFetchInterval = 2700;
        notifyOnNewExcludedQuests = false;
        notifyOnNewQuests = true;
        questButtonIndicator = "both";
        questButtonBadgeCount = 4;
        questButtonBadgeColor = 2842239;
        questButtonLeftClickAction = "open-quests";
        questButtonMiddleClickAction = "plugin-settings";
        questButtonRightClickAction = "context-menu";
        ignoredQuestIds.questIDs = [ ];
        questButtonIncludedTypes = {
          "1" = true;
          "2" = true;
          "3" = true;
          "4" = true;
          "5" = true;
          WATCH_VIDEO = true;
          WATCH_VIDEO_ON_MOBILE = true;
          ACHIEVEMENT_IN_ACTIVITY = true;
          ACHIEVEMENT_IN_GAME = true;
          PLAY_ACTIVITY = true;
          PLAY_ON_DESKTOP = true;
          PLAY_ON_DESKTOP_V2 = true;
          STREAM_ON_DESKTOP = true;
          PLAY_ON_PLAYSTATION = true;
          PLAY_ON_XBOX = true;
        };
        resumeInterruptedQuests = true;
        rememberQuestPageSort = true;
        lastQuestPageSort = "questify";
        rememberQuestPageFilters = true;
        lastQuestPageFilters = { };
        makeMobileVideoQuestsDesktopCompatible = true;
        unclaimedSubsort = "Expiring ASC";
        claimedSubsort = "Claimed DESC";
        ignoredSubsort = "Recent DESC";
        expiredSubsort = "Expiring DESC";
        questOrder = [
          "UNCLAIMED"
          "CLAIMED"
          "IGNORED"
          "EXPIRED"
        ];
        questTileUnclaimedColor = {
          enabled = true;
          color = 2842239;
        };
        questTileClaimedColor = {
          enabled = true;
          color = 6105983;
        };
        questTileIgnoredColor = {
          enabled = true;
          color = 8334124;
        };
        questTileExpiredColor = {
          enabled = true;
          color = 2368553;
        };
        questTileGradient = "intense";
        questTilePreload = true;
        newQuestAlertVolume = 100;
        newExcludedQuestAlertVolume = 100;
        notifyOnQuestComplete = true;
        questCompletedAlertSound = "bop_message1";
        questCompletedAlertVolume = 100;
        completeVideoQuestsQuicker = true;
        autoCompleteQuestsSimultaneously = true;
        resumeQuestIds = { };
      };
      readAllNotificationsButton.enable = true;
      relationshipNotifier.enable = true;
      replyTimestamp.enable = true;
      revealAllSpoilers.enable = true;
      serverInfo.enable = true;
      serverListIndicators.enable = true;
      showBadgesInChat.enable = true;
      showConnections.enable = true;
      showHiddenThings.enable = true;
      showTimeoutDuration.enable = true;
      silentTyping.enable = true;
      streamerModeOnStream.enable = true;
      themeAttributes.enable = true;
      translate.enable = true;
      typingIndicator.enable = true;
      typingTweaks.enable = true;
      unindent.enable = true;
      unlockedAvatarZoom.enable = true;
      userVoiceShow.enable = true;
      validReply.enable = true;
      validUser.enable = true;
      viewIcons.enable = true;
      voiceChatDoubleClick.enable = true;
      volumeBooster.enable = true;
      youtubeAdblock.enable = true;
    };
  };

  jsonConfig = nixcordConfig // {
    plugins = mapAttrs' (
      name: plugin: nameValuePair (pluginJsonName name) (pluginToJson plugin)
    ) nixcordConfig.plugins;
  };
in
{
  inherit
    jsonConfig
    nixcordConfig
    ;
}
