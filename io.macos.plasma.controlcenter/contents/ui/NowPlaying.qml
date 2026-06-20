import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// macOS-style Now Playing tile — album art, track info, playback controls
Rectangle {
    id: np
    height: 72
    radius: 14

    required property bool   isPlaying
    required property string trackTitle
    required property string trackArtist
    required property string trackArtUrl
    required property bool   canGoNext
    required property bool   canGoPrev
    required property color  tileColor
    required property color  textColor
    required property color  dimTextColor
    required property color  accent

    signal playPause
    signal next
    signal prev

    color: np.tileColor

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 10

        // Album art
        Rectangle {
            width: 48; height: 48
            radius: 8
            color: Qt.rgba(np.textColor.r, np.textColor.g, np.textColor.b, 0.1)
            Layout.alignment: Qt.AlignVCenter
            clip: true

            Image {
                anchors.fill: parent
                source: np.trackArtUrl
                fillMode: Image.PreserveAspectCrop
                visible: np.trackArtUrl !== ""
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                source: "media-optical-audio"
                width: 28; height: 28
                color: np.textColor
                visible: np.trackArtUrl === ""
            }
        }

        // Track info
        Column {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                width: parent.width
                text: np.trackTitle || "Unknown"
                font.pixelSize: 13
                font.weight: Font.DemiBold
                color: np.textColor
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: np.trackArtist || ""
                font.pixelSize: 11
                color: np.dimTextColor
                elide: Text.ElideRight
            }
        }

        // Playback controls
        Row {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            ControlBtn {
                iconName: "media-skip-backward"
                enabled: np.canGoPrev
                iconColor: np.textColor
                onClicked: np.prev()
            }

            ControlBtn {
                iconName: np.isPlaying ? "media-playback-pause" : "media-playback-start"
                iconColor: np.accent
                onClicked: np.playPause()
            }

            ControlBtn {
                iconName: "media-skip-forward"
                enabled: np.canGoNext
                iconColor: np.textColor
                onClicked: np.next()
            }
        }
    }
}
