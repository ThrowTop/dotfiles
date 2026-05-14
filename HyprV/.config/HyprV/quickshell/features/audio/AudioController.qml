import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    required property var shellRoot

    readonly property var defaultOutputDevice: Pipewire.defaultAudioSink
    property var outputDevices: []
    readonly property bool available: !!defaultOutputDevice && !!defaultOutputDevice.audio
    readonly property bool muted: available ? defaultOutputDevice.audio.muted : true
    readonly property real volume: available ? Math.max(0, Math.min(1, Number(defaultOutputDevice.audio.volume) || 0)) : 0
    readonly property int volumePercent: Math.max(0, Math.min(100, Math.round(volume * 100)))
    readonly property string defaultOutputName: deviceTitle(defaultOutputDevice)
    readonly property var trackedObjects: {
        const objects = [];
        if (defaultOutputDevice) {
            objects.push(defaultOutputDevice);
        }
        for (let i = 0; i < outputDevices.length; i++) {
            if (outputDevices[i] && objects.indexOf(outputDevices[i]) < 0) {
                objects.push(outputDevices[i]);
            }
        }
        return objects;
    }

    Component.onCompleted: refreshOutputDevices()

    PwObjectTracker {
        objects: root.trackedObjects
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged() { root.refreshOutputDevices(); }
        function onObjectInsertedPost() { root.refreshOutputDevices(); }
        function onObjectRemovedPost() { root.refreshOutputDevices(); }
    }

    Connections {
        target: Pipewire

        function onReadyChanged() { root.refreshOutputDevices(); }
        function onDefaultAudioSinkChanged() { root.refreshOutputDevices(); }
        function onDefaultConfiguredAudioSinkChanged() { root.refreshOutputDevices(); }
    }

    function refreshOutputDevices() {
        const nodes = Pipewire.nodes?.values || [];
        const nextDevices = [];

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.isSink || node.isStream || !node.audio) {
                continue;
            }
            nextDevices.push(node);
        }

        nextDevices.sort(function(a, b) {
            const aActive = root.isDefaultOutput(a) ? 0 : 1;
            const bActive = root.isDefaultOutput(b) ? 0 : 1;
            if (aActive !== bActive) {
                return aActive - bActive;
            }
            return root.deviceTitle(a).localeCompare(root.deviceTitle(b));
        });

        outputDevices = nextDevices;
    }

    function isDefaultOutput(device) {
        return !!device && !!defaultOutputDevice && device.id === defaultOutputDevice.id;
    }

    function deviceTitle(device) {
        if (!device) {
            return "No output device";
        }
        return device.nickname || device.description || device.name || "Audio output";
    }

    function deviceSubtitle(device) {
        if (!device) {
            return "Unavailable";
        }
        const props = device.properties || {};
        const parts = [];
        if (isDefaultOutput(device)) {
            parts.push("Selected");
        }
        if (props["device.description"] && props["device.description"] !== deviceTitle(device)) {
            parts.push(props["device.description"]);
        } else if (device.name && device.name !== deviceTitle(device)) {
            parts.push(device.name);
        }
        return parts.length > 0 ? parts.join("  •  ") : "Available output";
    }

    function deviceIcon(device) {
        const props = device?.properties || {};
        const icon = String(props["device.icon-name"] || props["node.icon-name"] || device?.name || "").toLowerCase();
        if (icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0) {
            return root.shellRoot.icons.headphones;
        }
        if (icon.indexOf("bluetooth") >= 0 || icon.indexOf("bluez") >= 0) {
            return root.shellRoot.icons.bluetooth;
        }
        if (icon.indexOf("hdmi") >= 0 || icon.indexOf("display") >= 0) {
            return root.shellRoot.icons.display;
        }
        if (icon.indexOf("speaker") >= 0) {
            return root.shellRoot.icons.speaker;
        }
        return root.shellRoot.icons.volumeHigh;
    }

    function setDefaultOutputDevice(device) {
        if (!device) {
            return;
        }
        Pipewire.preferredDefaultAudioSink = device;
    }

    function setVolumePercent(value) {
        if (!available) {
            return;
        }
        const nextValue = Math.max(0, Math.min(100, Math.round(value))) / 100;
        defaultOutputDevice.audio.volume = nextValue;
        if (nextValue > 0) {
            defaultOutputDevice.audio.muted = false;
        }
    }

    function adjustVolume(delta) {
        if (!available || delta === 0) {
            return;
        }
        setVolumePercent(volumePercent + delta);
    }

    function toggleMute() {
        if (!available) {
            return;
        }
        defaultOutputDevice.audio.muted = !defaultOutputDevice.audio.muted;
    }
}
