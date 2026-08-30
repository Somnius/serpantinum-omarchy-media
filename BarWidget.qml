import "Model.js" as Model
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

BarWidget {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: !!(sink && sink.audio)
    readonly property real volume: audioAvailable ? sink.audio.volume : 0
    readonly property bool muted: audioAvailable ? sink.audio.muted : true
    readonly property var allNodes: Pipewire.nodes ? Pipewire.nodes.values : []
    readonly property var allPlayers: Mpris.players ? Mpris.players.values : []
    property string preferredPlayerKey: ""
    readonly property var activePlayer: Model.selectPlayer(allPlayers, preferredPlayerKey)
    property var visibleOutputs: []
    property var visiblePlayers: []
    property bool popupOpen: false
    readonly property bool opened: popupOpen
    readonly property bool reduceMotion: setting("reduceMotion", false) === true
    readonly property real configuredMaxVolume: Number(setting("maxVolume", 100))
    readonly property int maxVolume: isFinite(configuredMaxVolume) ? Math.max(1, Math.min(150, configuredMaxVolume)) : 100

    function open() {
        popupOpen = true;
    }

    function close() {
        popupOpen = false;
    }

    function togglePanel() {
        popupOpen ? close() : open();
    }

    function closeForPopoutSwitch() {
        close();
    }

    function refreshVisibleModels() {
        if (!popupOpen)
            return ;

        var outputs = [];
        for (var i = 0; i < allNodes.length; i++) if (Model.isOutput(allNodes[i])) {
            outputs.push(allNodes[i]);
        }
        visibleOutputs = outputs;
        var players = [];
        for (var j = 0; j < allPlayers.length; j++) if (Model.hasPlayerContent(allPlayers[j])) {
            players.push(allPlayers[j]);
        }
        visiblePlayers = players;
    }

    function setVolume(value) {
        if (!audioAvailable)
            return ;

        sink.audio.volume = Model.clamp(value, 0, maxVolume / 100);
    }

    function toggleMute() {
        if (audioAvailable)
            sink.audio.muted = !sink.audio.muted;

    }

    function chooseOutput(node) {
        if (Model.isOutput(node))
            Pipewire.preferredDefaultAudioSink = node;

    }

    function choosePlayer(player) {
        preferredPlayerKey = Model.playerKey(player);
    }

    function previous() {
        if (activePlayer && activePlayer.canGoPrevious)
            activePlayer.previous();

    }

    function next() {
        if (activePlayer && activePlayer.canGoNext)
            activePlayer.next();

    }

    function playPause() {
        var player = activePlayer;
        if (!player)
            return ;

        if (player.canTogglePlaying)
            player.togglePlaying();
        else if (player.isPlaying && player.canPause)
            player.pause();
        else if (!player.isPlaying && player.canPlay)
            player.play();
    }

    moduleName: "somnius.serpantinum-media"
    onPopupOpenChanged: {
        if (popupOpen) {
            refreshVisibleModels();
            Qt.callLater(function() {
                mediaSurface.forceActiveFocus();
            });
        } else {
            visibleOutputs = [];
            visiblePlayers = [];
        }
    }
    onAllNodesChanged: {
        if (popupOpen)
            modelRefresh.restart();

    }
    onAllPlayersChanged: {
        if (popupOpen)
            modelRefresh.restart();

    }
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    PwObjectTracker {
        objects: root.popupOpen ? root.visibleOutputs : []
    }

    Timer {
        id: modelRefresh

        interval: 80
        repeat: false
        onTriggered: root.refreshVisibleModels()
    }

    BarIconButton {
        id: button

        anchors.fill: parent
        bar: root.bar
        text: Model.volumeIcon(root.volume, root.muted, root.audioAvailable)
        active: root.popupOpen
        tooltipText: root.audioAvailable ? (root.muted ? "Muted" : "Volume " + Model.volumePercent(root.volume) + "%") : "Audio unavailable"
        onPressed: function(mouseButton) {
            if (mouseButton === Qt.RightButton)
                root.toggleMute();
            else
                root.togglePanel();
        }
        onWheelMoved: function(delta) {
            root.setVolume(root.volume + (delta > 0 ? 0.05 : -0.05));
        }
    }

    PopupCard {
        id: popup

        anchorItem: button
        bar: root.bar
        owner: root
        open: root.popupOpen
        contentWidth: popup.fittedContentWidth(Style.space(360))
        contentHeight: popup.fittedContentHeight(Math.min(content.implicitHeight, Style.space(620)))

        Flickable {
            id: mediaSurface

            anchors.fill: parent
            contentWidth: width
            contentHeight: content.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            clip: true
            focus: root.popupOpen
            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: root.setVolume(root.volume - 0.05)
            Keys.onRightPressed: root.setVolume(root.volume + 0.05)
            Keys.onSpacePressed: root.playPause()

            Column {
                id: content

                width: parent.width
                spacing: Style.space(12)
                opacity: root.popupOpen ? 1 : 0
                scale: root.popupOpen ? 1 : 0.97

                Row {
                    width: parent.width
                    spacing: Style.space(10)

                    Rectangle {
                        width: Style.space(72)
                        height: width
                        radius: Style.space(12)
                        color: Color.accent
                        opacity: 0.86

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * Model.clamp(root.volume, 0, 1)
                            radius: parent.radius
                            color: root.bar ? root.bar.foreground : Color.foreground
                            opacity: root.muted ? 0.18 : 0.42

                            Behavior on height {
                                NumberAnimation {
                                    duration: root.reduceMotion ? 0 : 260
                                    easing.type: Easing.OutCubic
                                }

                            }

                        }

                        Text {
                            anchors.centerIn: parent
                            text: Model.volumeIcon(root.volume, root.muted, root.audioAvailable)
                            color: root.bar ? root.bar.foreground : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.displayLarge
                        }

                    }

                    Column {
                        width: parent.width - Style.space(82)
                        spacing: Style.space(6)

                        Text {
                            width: parent.width
                            text: root.audioAvailable ? (root.muted ? "Audio muted" : "Output volume") : "Audio unavailable"
                            color: root.bar ? root.bar.foreground : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.subtitle
                            font.bold: true
                        }

                        Text {
                            text: root.audioAvailable ? Model.volumePercent(root.volume) + "%" : "PipeWire has no active output"
                            color: root.bar ? root.bar.foreground : Color.foreground
                            opacity: 0.7
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.body
                        }

                        Slider {
                            width: parent.width
                            enabled: root.audioAvailable
                            from: 0
                            to: root.maxVolume / 100
                            value: root.volume
                            onMoved: root.setVolume(value)
                        }

                        Button {
                            text: root.muted ? "Unmute" : "Mute"
                            enabled: root.audioAvailable
                            onClicked: root.toggleMute()
                        }

                    }

                }

                PanelSeparator {
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                }

                Text {
                    text: "OUTPUT"
                    color: root.bar ? root.bar.foreground : Color.foreground
                    opacity: 0.65
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.caption
                    font.bold: true
                }

                Text {
                    visible: root.visibleOutputs.length === 0
                    text: "No audio outputs are currently available"
                    color: root.bar ? root.bar.foreground : Color.foreground
                    opacity: 0.65
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                    font.pixelSize: Style.font.bodySmall
                }

                Repeater {
                    model: root.visibleOutputs

                    delegate: Button {
                        required property var modelData

                        width: content.width
                        text: (modelData === root.sink ? "●  " : "○  ") + Model.outputLabel(modelData)
                        onClicked: root.chooseOutput(modelData)
                    }

                }

                PanelSeparator {
                    foreground: root.bar ? root.bar.foreground : Color.foreground
                }

                Row {
                    width: parent.width
                    spacing: Style.space(10)

                    Rectangle {
                        width: Style.space(72)
                        height: width
                        radius: Style.space(12)
                        color: Color.accent
                        opacity: 0.68
                        clip: true

                        Image {
                            id: artwork

                            anchors.fill: parent
                            source: root.popupOpen && root.activePlayer && root.activePlayer.trackArtUrl ? root.activePlayer.trackArtUrl : ""
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: artwork.status !== Image.Ready
                            text: "󰝚"
                            color: root.bar ? root.bar.foreground : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.displayLarge
                        }

                    }

                    Column {
                        width: parent.width - Style.space(82)
                        spacing: Style.space(4)

                        Text {
                            width: parent.width
                            text: Model.title(root.activePlayer)
                            color: root.bar ? root.bar.foreground : Color.foreground
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.subtitle
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: Model.subtitle(root.activePlayer)
                            color: root.bar ? root.bar.foreground : Color.foreground
                            opacity: 0.68
                            font.family: root.bar ? root.bar.fontFamily : Style.font.family
                            font.pixelSize: Style.font.bodySmall
                            elide: Text.ElideRight
                        }

                        Row {
                            spacing: Style.space(6)

                            Button {
                                text: "󰒮"
                                enabled: root.activePlayer && root.activePlayer.canGoPrevious
                                onClicked: root.previous()
                            }

                            Button {
                                text: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
                                enabled: root.activePlayer && (root.activePlayer.canTogglePlaying || root.activePlayer.canPlay || root.activePlayer.canPause)
                                onClicked: root.playPause()
                            }

                            Button {
                                text: "󰒭"
                                enabled: root.activePlayer && root.activePlayer.canGoNext
                                onClicked: root.next()
                            }

                        }

                    }

                }

                Flow {
                    visible: root.visiblePlayers.length > 1
                    width: parent.width
                    height: childrenRect.height
                    spacing: Style.space(6)

                    Repeater {
                        model: root.visiblePlayers

                        delegate: Button {
                            required property var modelData

                            text: Model.playerLabel(modelData)
                            onClicked: root.choosePlayer(modelData)
                        }

                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: root.reduceMotion ? 0 : 180
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: root.reduceMotion ? 0 : 220
                        easing.type: Easing.OutCubic
                    }

                }

            }

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

        }

    }

}
