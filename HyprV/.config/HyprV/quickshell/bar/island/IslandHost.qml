import QtQuick
import "../.."

DynamicIsland {
    id: islandHost

    property var parentWindow: null
    property var collapseTimer: null

    now: islandHost.shellRoot.now
    mediaAvailable: islandHost.shellRoot.mediaAvailable
    mediaPlaying: islandHost.shellRoot.mediaPlaying
    mediaTitle: islandHost.shellRoot.mediaTitle
    mediaArtist: islandHost.shellRoot.mediaArtist
    mediaPlayerName: islandHost.shellRoot.mediaPlayerName
    mediaArtUrl: islandHost.shellRoot.mediaArtUrl
    mediaPositionSeconds: islandHost.shellRoot.mediaPositionSeconds
    mediaLengthSeconds: islandHost.shellRoot.mediaLengthSeconds
    spectrumValues: islandHost.shellRoot.audioSpectrumValues

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

    onLockClicked: islandHost.shellRoot.runDetached(["hyprlock"])
    onSeekRequested: function(positionSeconds) {
        islandHost.shellRoot.seekMedia(positionSeconds);
    }
    onAppFocusRequested: islandHost.shellRoot.focusMediaApp()
    onPreviousClicked: islandHost.shellRoot.previousMedia()
    onPlayPauseClicked: islandHost.shellRoot.toggleMediaPlayback()
    onNextClicked: islandHost.shellRoot.nextMedia()
}
