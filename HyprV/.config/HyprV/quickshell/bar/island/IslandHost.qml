import QtQuick
import "../.."

DynamicIsland {
    id: islandHost

    property var parentWindow: null
    property var collapseTimer: null

    now: islandHost.shellRoot ? islandHost.shellRoot.now : new Date()
    mediaAvailable: islandHost.shellRoot ? islandHost.shellRoot.mediaAvailable : false
    mediaPlaying: islandHost.shellRoot ? islandHost.shellRoot.mediaPlaying : false
    mediaTitle: islandHost.shellRoot ? islandHost.shellRoot.mediaTitle : ""
    mediaArtist: islandHost.shellRoot ? islandHost.shellRoot.mediaArtist : ""
    mediaPlayerName: islandHost.shellRoot ? islandHost.shellRoot.mediaPlayerName : ""
    mediaArtUrl: islandHost.shellRoot ? islandHost.shellRoot.mediaArtUrl : ""
    mediaPositionSeconds: islandHost.shellRoot ? islandHost.shellRoot.mediaPositionSeconds : 0
    mediaLengthSeconds: islandHost.shellRoot ? islandHost.shellRoot.mediaLengthSeconds : 0
    spectrumValues: islandHost.shellRoot ? islandHost.shellRoot.audioSpectrumValues : []

    onExpandedChanged: {
        if (!islandHost.parentWindow || !islandHost.collapseTimer) {
            return;
        }
        if (expanded) {
            islandHost.collapseTimer.stop();
            islandHost.parentWindow.islandExpanded = true;
        } else {
            islandHost.collapseTimer.restart();
        }
    }

    onHeightChanged: if (islandHost.parentWindow) {
        islandHost.parentWindow.islandCurrentHeight = height;
    }

    onLockClicked: if (islandHost.shellRoot) islandHost.shellRoot.runDetached(["hyprlock"])
    onSeekRequested: function(positionSeconds) {
        if (islandHost.shellRoot) {
            islandHost.shellRoot.seekMedia(positionSeconds);
        }
    }
    onAppFocusRequested: if (islandHost.shellRoot) islandHost.shellRoot.focusMediaApp()
    onPreviousClicked: if (islandHost.shellRoot) islandHost.shellRoot.previousMedia()
    onPlayPauseClicked: if (islandHost.shellRoot) islandHost.shellRoot.toggleMediaPlayback()
    onNextClicked: if (islandHost.shellRoot) islandHost.shellRoot.nextMedia()
}
