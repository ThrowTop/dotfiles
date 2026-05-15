import QtQuick
import "../.."

DynamicIsland {
    id: islandHost

    property var parentWindow: null
    property var collapseTimer: null

    now: islandHost.shellRoot.now
    mediaAvailable: islandHost.shellRoot.media.available
    mediaPlaying: islandHost.shellRoot.media.playing
    mediaTitle: islandHost.shellRoot.media.title
    mediaArtist: islandHost.shellRoot.media.artist
    mediaPlayerName: islandHost.shellRoot.media.playerName
    mediaArtUrl: islandHost.shellRoot.media.artUrl
    mediaPositionSeconds: islandHost.shellRoot.media.positionSeconds
    mediaLengthSeconds: islandHost.shellRoot.media.lengthSeconds
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
        islandHost.shellRoot.media.seek(positionSeconds);
    }
    onAppFocusRequested: islandHost.shellRoot.media.focusApp()
    onPreviousClicked: islandHost.shellRoot.media.previous()
    onPlayPauseClicked: islandHost.shellRoot.media.togglePlayback()
    onNextClicked: islandHost.shellRoot.media.next()
}
