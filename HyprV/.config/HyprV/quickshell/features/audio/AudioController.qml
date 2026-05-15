import QtQuick
import Quickshell.Services.Pipewire

Item {
    id: root

    required property var shellRoot

    readonly property var defaultOutputDevice: Pipewire.defaultAudioSink
    readonly property var defaultInputDevice: Pipewire.defaultAudioSource
    property var outputDevices: []
    property var inputDevices: []
    property var streamDevices: []

    readonly property bool available: !!defaultOutputDevice && !!defaultOutputDevice.audio
    readonly property bool muted: available ? defaultOutputDevice.audio.muted : true
    readonly property real volume: available ? Math.max(0, Math.min(1, Number(defaultOutputDevice.audio.volume) || 0)) : 0
    readonly property int volumePercent: Math.max(0, Math.min(100, Math.round(volume * 100)))
    readonly property string defaultOutputName: deviceTitle(defaultOutputDevice)

    readonly property bool inputAvailable: !!defaultInputDevice && !!defaultInputDevice.audio
    readonly property bool inputMuted: inputAvailable ? defaultInputDevice.audio.muted : true
    readonly property real inputVolume: inputAvailable ? Math.max(0, Math.min(1, Number(defaultInputDevice.audio.volume) || 0)) : 0
    readonly property int inputVolumePercent: Math.max(0, Math.min(100, Math.round(inputVolume * 100)))
    readonly property string defaultInputName: deviceTitle(defaultInputDevice)

    readonly property var trackedObjects: {
        const objects = [];
        if (defaultOutputDevice) objects.push(defaultOutputDevice);
        if (defaultInputDevice) objects.push(defaultInputDevice);
        for (let i = 0; i < outputDevices.length; i++) {
            if (outputDevices[i] && objects.indexOf(outputDevices[i]) < 0)
                objects.push(outputDevices[i]);
        }
        for (let i = 0; i < inputDevices.length; i++) {
            if (inputDevices[i] && objects.indexOf(inputDevices[i]) < 0)
                objects.push(inputDevices[i]);
        }
        for (let i = 0; i < streamDevices.length; i++) {
            if (streamDevices[i] && objects.indexOf(streamDevices[i]) < 0)
                objects.push(streamDevices[i]);
        }
        return objects;
    }

    Component.onCompleted: refreshDevices()

    PwObjectTracker {
        objects: root.trackedObjects
    }

    Connections {
        target: Pipewire.nodes

        function onValuesChanged() { root.refreshDevices(); }
        function onObjectInsertedPost() { root.refreshDevices(); }
        function onObjectRemovedPost() { root.refreshDevices(); }
    }

    Connections {
        target: Pipewire

        function onReadyChanged() { root.refreshDevices(); }
        function onDefaultAudioSinkChanged() { root.refreshDevices(); }
        function onDefaultConfiguredAudioSinkChanged() { root.refreshDevices(); }
        function onDefaultAudioSourceChanged() { root.refreshDevices(); }
        function onDefaultConfiguredAudioSourceChanged() { root.refreshDevices(); }
    }

    function refreshDevices() {
        const nodes = Pipewire.nodes?.values || [];
        const nextOutputs = [];
        const nextInputs = [];
        const nextStreams = [];

        for (let i = 0; i < nodes.length; i++) {
            const node = nodes[i];
            if (!node || !node.audio) continue;
            if (node.isStream) {
                if (node.isSink) nextStreams.push(node);
            } else if (node.isSink) {
                nextOutputs.push(node);
            } else {
                nextInputs.push(node);
            }
        }

        nextOutputs.sort((a, b) => deviceTitle(a).localeCompare(deviceTitle(b)));
        nextInputs.sort((a, b) => deviceTitle(a).localeCompare(deviceTitle(b)));
        nextStreams.sort((a, b) => streamTitle(a).localeCompare(streamTitle(b)));

        outputDevices = nextOutputs;
        inputDevices = nextInputs;
        streamDevices = nextStreams;
    }

    function streamTitle(node) {
        if (!node) return "Unknown";
        const props = node.properties || {};
        return String(props["application.name"] || props["media.name"] || node.description || node.name || "Audio stream");
    }

    function streamIconName(node) {
        if (!node) return "";
        const props = node.properties || {};
        return String(props["application.icon-name"] || "");
    }

    function setStreamVolumePercent(node, value) {
        if (!node?.audio) return;
        const next = Math.max(0, Math.min(100, Math.round(value))) / 100;
        node.audio.volume = next;
        if (next > 0) node.audio.muted = false;
    }

    function toggleStreamMute(node) {
        if (!node?.audio) return;
        node.audio.muted = !node.audio.muted;
    }

    function isDefaultOutput(device) {
        return !!device && !!defaultOutputDevice && device.id === defaultOutputDevice.id;
    }

    function isDefaultInput(device) {
        return !!device && !!defaultInputDevice && device.id === defaultInputDevice.id;
    }

    function deviceTitle(device) {
        if (!device) return "No device";
        const name = String(device.name || "");
        if (name.indexOf("alsa_output.pci") >= 0 || name.indexOf("alsa_input.pci") >= 0) {
            return device.isSink ? "Internal Speakers" : "Internal Microphone";
        }
        return device.nickname || device.description || device.name || "Audio device";
    }

    function deviceSubtitle(device, isInput) {
        if (!device) return "Unavailable";
        const props = device.properties || {};
        const title = deviceTitle(device);
        const cardDesc = String(props["device.description"] || "");
        if (cardDesc.length > 0 && cardDesc !== title) return cardDesc;
        return isInput ? "Audio input" : "Audio output";
    }

    function deviceIcon(device, isInput) {
        const props = device?.properties || {};
        const icon = String(props["device.icon-name"] || props["node.icon-name"] || device?.name || "").toLowerCase();
        if (icon.indexOf("headset") >= 0 || icon.indexOf("headphone") >= 0)
            return shellRoot.icons.headphones;
        if (icon.indexOf("bluetooth") >= 0 || icon.indexOf("bluez") >= 0)
            return shellRoot.icons.bluetooth;
        if (icon.indexOf("hdmi") >= 0 || icon.indexOf("display") >= 0)
            return shellRoot.icons.display;
        if (icon.indexOf("microphone") >= 0 || icon.indexOf("audio-input") >= 0)
            return shellRoot.icons.microphone;
        if (icon.indexOf("speaker") >= 0)
            return shellRoot.icons.speaker;
        return isInput ? shellRoot.icons.microphone : shellRoot.icons.volumeHigh;
    }

    function setDefaultOutputDevice(device) {
        if (!device) return;
        Pipewire.preferredDefaultAudioSink = device;
    }

    function setDefaultInputDevice(device) {
        if (!device) return;
        Pipewire.preferredDefaultAudioSource = device;
    }

    function setVolumePercent(value) {
        if (!available) return;
        const next = Math.max(0, Math.min(100, Math.round(value))) / 100;
        defaultOutputDevice.audio.volume = next;
        if (next > 0) defaultOutputDevice.audio.muted = false;
    }

    function adjustVolume(delta) {
        if (!available || delta === 0) return;
        setVolumePercent(volumePercent + delta);
    }

    function toggleMute() {
        if (!available) return;
        defaultOutputDevice.audio.muted = !defaultOutputDevice.audio.muted;
    }

    function setInputVolumePercent(value) {
        if (!inputAvailable) return;
        const next = Math.max(0, Math.min(100, Math.round(value))) / 100;
        defaultInputDevice.audio.volume = next;
        if (next > 0) defaultInputDevice.audio.muted = false;
    }

    function toggleInputMute() {
        if (!inputAvailable) return;
        defaultInputDevice.audio.muted = !defaultInputDevice.audio.muted;
    }
}
