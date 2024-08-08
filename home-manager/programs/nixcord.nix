{ pkgs, ... }:
{
  programs.nixcord = {
    enable = true;
    openASAR.enable = false;
    discord.enable = if pkgs.stdenv.isLinux then false else true;
    vesktop.enable = if pkgs.stdenv.isLinux then true else false;
    quickCss = builtins.readFile ./config/quickCSS.css;
    config = {
      useQuickCss = true; # use out quickCSS
      frameless = true; # set some Vencord options
      plugins = {
        automodContext.enable = true;
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
        crashHandler.enable = true;
        dearrow.enable = true;
        disableCallIdle.enable = true;
        favoriteEmojiFirst.enable = true;
        fixCodeblockGap.enable = true;
        fixSpotifyEmbeds.enable = true;
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        friendInvites.enable = true;
        friendsSince.enable = true;
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
        implicitRelationships.enable = true;
        imageZoom.enable = true;
        memberCount.enable = true;
        messageLatency.enable = true;
        messageLinkEmbeds.enable = true;
        messageLogger.enable = true;
        messageTags.enable = true;
        moreUserTags.enable = true;
        mutualGroupDMs.enable = true;
        newGuildSettings.enable = true;
        noBlockedMessages.enable = true;
        noDevtoolsWarning.enable = true;
        noF1.enable = true;
        noMosaic.enable = true;
        noPendingCount.enable = true;
        noProfileThemes.enable = true;
        noRPC.enable = true;
        noScreensharePreview.enable = true;
        noTypingAnimation.enable = true;
        noUnblockToJump.enable = true;
        normalizeMessageLinks.enable = true;
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
        searchReply.enable = true;
        serverInfo.enable = true;
        serverListIndicators.enable = true;
        shikiCodeblocks.enable = true;
        showConnections.enable = true;
        showHiddenThings.enable = true;
        showMeYourName.enable = true;
        silentTyping.enable = true;
        spotifyShareCommands.enable = true;
        startupTimings.enable = true;
        streamerModeOnStream.enable = true;
        summaries.enable = true;
        superReactionTweaks.enable = true;
        textReplace.enable = true;
        themeAttributes.enable = true;
        translate.enable = true;
        typingIndicator.enable = true;
        typingTweaks.enable = true;
        unindent.enable = true;
        unlockedAvatarZoom.enable = true;
        userVoiceShow.enable = true;
        validUser.enable = true;
        vencordToolbox.enable = true;
        viewIcons.enable = true;
        viewRaw.enable = true;
        voiceDownload.enable = true;
        voiceMessages.enable = true;
        volumeBooster.enable = true;
        watchTogetherAdblock.enable = true;
        whoReacted.enable = true;
      };
    };
  };
}
