import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.networkmanagement as PlasmaNM
import org.kde.plasma.private.volume as PulseAudio
import org.kde.plasma.private.brightnesscontrolplugin as BrightnessPlugin
import org.kde.plasma.private.mpris as Mpris
import org.kde.bluezqt as BluezQt
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    // ── Network ──────────────────────────────────────────────────────────────
    PlasmaNM.Handler          { id: nmHandler }
    PlasmaNM.ConnectionIcon   { id: nmIcon }
    PlasmaNM.WirelessStatus   { id: nmWireless }
    PlasmaNM.EnabledConnections { id: nmEnabled }

    readonly property bool   wifiOn:   nmEnabled.wirelessEnabled
    readonly property string wifiSSID: nmWireless.wifiSSID
    readonly property bool   wifiConnected: wifiSSID !== ""

    // ── Bluetooth ─────────────────────────────────────────────────────────────
    // Manager is a singleton — access via type name, do not instantiate
    readonly property bool   btAvailable: BluezQt.Manager.bluetoothOperational
    readonly property bool   btOn:        btAvailable
                                          && BluezQt.Manager.usableAdapter !== null
                                          && BluezQt.Manager.usableAdapter.powered

    function toggleBluetooth() {
        if (BluezQt.Manager.usableAdapter) {
            BluezQt.Manager.usableAdapter.powered = !btOn
        }
    }

    // ── Volume ────────────────────────────────────────────────────────────────
    PulseAudio.SinkModel { id: sinkModel }

    readonly property var  activeSink:  sinkModel.count > 0
        ? sinkModel.data(sinkModel.index(0, 0), sinkModel.role("PulseObject")) : null
    readonly property int  volumePct:   activeSink ? Math.round(activeSink.volume / 65536 * 100) : 0
    readonly property bool muted:       activeSink ? activeSink.muted : false

    function setVolume(pct) {
        if (activeSink) activeSink.volume = Math.round(Math.max(0, Math.min(pct, 100)) / 100 * 65536)
    }
    function toggleMute() { if (activeSink) activeSink.muted = !muted }

    // ── Brightness ────────────────────────────────────────────────────────────
    BrightnessPlugin.ScreenBrightnessControl { id: brightnessCtl; isSilent: true }

    // brightness lives in the displays model — track the first display's values
    property int    brightnessPct:     0
    property int    _brightnessMax:    0
    property string _brightnessDisplay: ""

    Instantiator {
        model: brightnessCtl.displays
        delegate: QtObject {
            required property string displayName
            required property int    brightness
            required property int    brightnessMax
        }
        onObjectAdded: function(index, obj) {
            if (index !== 0) return
            root._brightnessDisplay = obj.displayName
            root._brightnessMax     = obj.brightnessMax
            root.brightnessPct      = obj.brightnessMax > 0
                ? Math.round(obj.brightness / obj.brightnessMax * 100) : 0
            obj.brightnessChanged.connect(function() {
                root.brightnessPct = obj.brightnessMax > 0
                    ? Math.round(obj.brightness / obj.brightnessMax * 100) : 0
            })
            obj.brightnessMaxChanged.connect(function() {
                root._brightnessMax = obj.brightnessMax
            })
        }
        onObjectRemoved: function(index, obj) {
            if (index === 0) root.brightnessPct = 0
        }
    }

    function setBrightness(pct) {
        var delta = _brightnessMax > 0
            ? (pct - brightnessPct) / 100.0   // Instantiator gave us real current value
            : (pct - 50) / 50.0               // fallback: treat slider as relative step
        brightnessCtl.adjustBrightnessRatio(delta)
    }

    // ── Now Playing ───────────────────────────────────────────────────────────
    Mpris.Mpris2Model { id: mpris2 }
    readonly property var  player:        mpris2.currentPlayer
    readonly property bool hasPlayer:     player !== null && player !== undefined
    readonly property bool isPlaying:     hasPlayer && player.playbackStatus === Mpris.PlaybackStatus.Playing

    // ── Popup ─────────────────────────────────────────────────────────────────
    property bool popupOpen: false

    PlasmaCore.Dialog {
        id: ccDialog
        visible: root.popupOpen
        flags: Qt.WindowDoesNotAcceptFocus
        location: PlasmaCore.Types.TopEdge

        mainItem: ControlCenterPopup {
            // wifi
            wifiOn:        root.wifiOn
            wifiSSID:      root.wifiSSID
            wifiConnected: root.wifiConnected
            // bluetooth
            btOn:          root.btOn
            btAvailable:   root.btAvailable
            // volume
            volumePct:     root.volumePct
            muted:         root.muted
            // brightness
            brightnessAvailable: brightnessCtl.isBrightnessAvailable
            brightnessPct:       root.brightnessPct
            // now playing
            hasPlayer:     root.hasPlayer
            isPlaying:     root.isPlaying
            trackTitle:    root.hasPlayer ? (root.player.track  || "") : ""
            trackArtist:   root.hasPlayer ? (root.player.artist || "") : ""
            trackArtUrl:   root.hasPlayer ? (root.player.artUrl || "") : ""
            canGoNext:     root.hasPlayer && root.player.canGoNext
            canGoPrev:     root.hasPlayer && root.player.canGoPrevious

            onToggleWifi:      nmHandler.enableWireless(!root.wifiOn)
            onToggleBluetooth: root.toggleBluetooth()
            onToggleMute:      root.toggleMute()
            onSetVolume:       function(v) { root.setVolume(v) }
            onSetBrightness:   function(v) { root.setBrightness(v) }
            onPlayerPlayPause: if (root.hasPlayer) root.player.PlayPause()
            onPlayerNext:      if (root.hasPlayer) root.player.Next()
            onPlayerPrev:      if (root.hasPlayer) root.player.Previous()
            onClose:           root.popupOpen = false
        }
    }

    // ── Compact bar icon ──────────────────────────────────────────────────────
    compactRepresentation: Item {
        id: compactItem
        Layout.preferredWidth: 32
        Layout.fillHeight: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (root.popupOpen) {
                    root.popupOpen = false
                } else {
                    ccDialog.visualParent = compactItem
                    root.popupOpen = true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: parent.containsMouse || root.popupOpen
                    ? Qt.rgba(1,1,1,0.15) : "transparent"
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                source: Qt.resolvedUrl("control-center-icon.svg")
                width: 16; height: 16
            }
        }
    }

    fullRepresentation: compactRepresentation
}
