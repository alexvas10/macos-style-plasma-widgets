import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// macOS-style Control Center panel
Item {
    id: root
    implicitWidth: 300
    implicitHeight: col.implicitHeight + 20

    // ── inputs ────────────────────────────────────────────────────────────────
    required property bool   wifiOn
    required property string wifiSSID
    required property bool   wifiConnected
    required property bool   btOn
    required property bool   btAvailable
    required property int    volumePct
    required property bool   muted
    required property bool   brightnessAvailable
    required property int    brightnessPct
    required property bool   hasPlayer
    required property bool   isPlaying
    required property string trackTitle
    required property string trackArtist
    required property string trackArtUrl
    required property bool   canGoNext
    required property bool   canGoPrev

    // ── signals ───────────────────────────────────────────────────────────────
    signal toggleWifi
    signal toggleBluetooth
    signal toggleMute
    signal setVolume(int v)
    signal setBrightness(int v)
    signal playerPlayPause
    signal playerNext
    signal playerPrev
    signal close

    // keep local copies so sliders stay smooth while dbus catches up
    property int localVol:        volumePct
    onVolumePctChanged:     if (!volSlider.pressed)    localVol        = volumePct

    property int localBrightness: brightnessPct
    onBrightnessPctChanged: if (!brightnessSlider.pressed) localBrightness = brightnessPct

    // ── palette helpers ───────────────────────────────────────────────────────
    readonly property color surfaceColor:   Qt.rgba(
        Kirigami.Theme.backgroundColor.r,
        Kirigami.Theme.backgroundColor.g,
        Kirigami.Theme.backgroundColor.b, 0.92)
    readonly property color tileColor:      Qt.rgba(
        Kirigami.Theme.alternateBackgroundColor.r,
        Kirigami.Theme.alternateBackgroundColor.g,
        Kirigami.Theme.alternateBackgroundColor.b, 1)
    readonly property color tileActiveColor: Qt.rgba(
        Kirigami.Theme.highlightColor.r,
        Kirigami.Theme.highlightColor.g,
        Kirigami.Theme.highlightColor.b, 0.9)
    readonly property color textColor:      Kirigami.Theme.textColor
    readonly property color dimTextColor:   Qt.rgba(textColor.r, textColor.g, textColor.b, 0.55)
    readonly property color activeTextColor: Kirigami.Theme.highlightedTextColor
    readonly property color sliderTrack:    Qt.rgba(textColor.r, textColor.g, textColor.b, 0.18)

    Column {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top }
        anchors.margins: 10
        spacing: 8

        // ── Row 1: WiFi + Bluetooth tiles ────────────────────────────────────
        Row {
            width: parent.width
            spacing: 8

            MacTile {
                width: (parent.width - 8) / 2
                height: 80
                active: root.wifiOn
                iconName: root.wifiOn && root.wifiConnected
                    ? "network-wireless-connected-100"
                    : root.wifiOn ? "network-wireless-on"
                    : "network-wireless-disconnected"
                label:    "Wi-Fi"
                sublabel: root.wifiConnected ? root.wifiSSID
                         : root.wifiOn       ? "On, not connected"
                         : "Off"
                tileColor:       root.tileColor
                tileActiveColor: root.tileActiveColor
                textColor:       root.textColor
                dimTextColor:    root.dimTextColor
                activeTextColor: root.activeTextColor
                onToggle: root.toggleWifi()
            }

            MacTile {
                width: (parent.width - 8) / 2
                height: 80
                active: root.btOn
                iconName: root.btOn
                    ? "preferences-system-bluetooth-activated"
                    : "preferences-system-bluetooth-inactive"
                label:    "Bluetooth"
                sublabel: root.btOn ? "On" : "Off"
                tileColor:       root.tileColor
                tileActiveColor: root.tileActiveColor
                textColor:       root.textColor
                dimTextColor:    root.dimTextColor
                activeTextColor: root.activeTextColor
                onToggle: root.toggleBluetooth()
            }
        }

        // ── Brightness slider (hidden on desktops) ────────────────────────────
        MacSliderRow {
            id: brightnessSlider
            width: parent.width
            visible: root.brightnessAvailable
            iconName: "display-brightness"
            value: root.localBrightness
            tileColor:   root.tileColor
            textColor:   root.textColor
            sliderTrack: root.sliderTrack
            accent:      Kirigami.Theme.highlightColor
            onMoved: function(v) {
                root.localBrightness = v
                root.setBrightness(v)
            }
        }

        // ── Volume slider ─────────────────────────────────────────────────────
        MacSliderRow {
            id: volSlider
            width: parent.width
            iconName: root.muted || root.volumePct === 0 ? "audio-volume-muted"
                    : root.localVol < 34 ? "audio-volume-low"
                    : root.localVol < 67 ? "audio-volume-medium"
                    : "audio-volume-high"
            value: root.localVol
            tileColor:  root.tileColor
            textColor:  root.textColor
            sliderTrack: root.sliderTrack
            accent:     Kirigami.Theme.highlightColor
            onIconClicked: root.toggleMute()
            onMoved: function(v) {
                root.localVol = v
                root.setVolume(v)
            }
        }

        // ── Now Playing ───────────────────────────────────────────────────────
        NowPlaying {
            width: parent.width
            visible: root.hasPlayer
            isPlaying:    root.isPlaying
            trackTitle:   root.trackTitle
            trackArtist:  root.trackArtist
            trackArtUrl:  root.trackArtUrl
            canGoNext:    root.canGoNext
            canGoPrev:    root.canGoPrev
            tileColor:    root.tileColor
            textColor:    root.textColor
            dimTextColor: root.dimTextColor
            accent:       Kirigami.Theme.highlightColor
            onPlayPause:  root.playerPlayPause()
            onNext:       root.playerNext()
            onPrev:       root.playerPrev()
        }

        Item { height: 2 }
    }
}
