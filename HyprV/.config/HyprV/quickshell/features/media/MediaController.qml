import QtQuick
import Quickshell.Services.Mpris

Item {
    id: controller

    required property var shellRoot

    readonly property var players: Array.from(Mpris.players.values || [])
    readonly property var activePlayer: preferredPlayer()
    readonly property bool available: activePlayer !== null
    readonly property bool playing: activePlayer ? activePlayer.isPlaying : false
    readonly property string title: activePlayer ? activePlayer.trackTitle : ""
    readonly property string artist: activePlayer ? activePlayer.trackArtist : ""
    readonly property string playerName: activePlayer ? (activePlayer.identity || activePlayer.dbusName || "") : ""
    readonly property string artUrl: activePlayer ? activePlayer.trackArtUrl : ""
    property real positionSeconds: activePlayer ? Math.max(0, activePlayer.position || 0) : 0
    readonly property real lengthSeconds: activePlayer ? Math.max(0, activePlayer.length || 0) : 0

    onActivePlayerChanged: refresh()
    onPlayingChanged: refresh()

    Timer {
        interval: 1000
        repeat: true
        running: controller.available && controller.playing
        onTriggered: if (controller.activePlayer) {
            controller.positionSeconds = Math.max(0, controller.activePlayer.position || controller.positionSeconds + 1);
        }
    }

    function preferredPlayer() {
        const currentPlayers = controller.players;
        if (!currentPlayers || currentPlayers.length === 0) {
            return null;
        }

        let fallback = null;
        let paused = null;
        let content = null;
        let pausedContent = null;
        for (let i = 0; i < currentPlayers.length; i++) {
            const player = currentPlayers[i];
            if (!player) {
                continue;
            }
            if (!fallback) {
                fallback = player;
            }
            if (player.isPlaying) {
                return player;
            }
            if (!paused && player.playbackState === MprisPlaybackState.Paused) {
                paused = player;
            }
            const hasContent = (player.trackTitle || "").length > 0
                || (player.trackArtist || "").length > 0
                || (player.trackArtUrl || "").length > 0;
            if (hasContent) {
                if (!content) {
                    content = player;
                }
                if (!pausedContent && player.playbackState === MprisPlaybackState.Paused) {
                    pausedContent = player;
                }
            }
        }

        return pausedContent || content || paused || fallback;
    }

    function refresh() {
        positionSeconds = activePlayer ? Math.max(0, activePlayer.position || 0) : 0;
    }

    function seek(positionSecondsValue) {
        const rawTarget = Number(positionSecondsValue);
        if (!isFinite(rawTarget) || !activePlayer) {
            return;
        }
        const duration = Number(lengthSeconds);
        const target = duration > 0 ? Math.max(0, Math.min(duration, rawTarget)) : Math.max(0, rawTarget);
        positionSeconds = target;
        activePlayer.position = target;
    }

    function previous() {
        if (activePlayer) {
            activePlayer.previous();
        }
    }

    function togglePlayback() {
        if (activePlayer) {
            activePlayer.togglePlaying();
        }
    }

    function next() {
        if (activePlayer) {
            activePlayer.next();
        }
    }

    function focusApp() {
        const dbusName = activePlayer ? (activePlayer.dbusName || "").trim() : "";
        if (dbusName.length === 0) {
            return;
        }
        shellRoot.runDetached([shellRoot.mediaFocusScriptPath, dbusName]);
    }
}
