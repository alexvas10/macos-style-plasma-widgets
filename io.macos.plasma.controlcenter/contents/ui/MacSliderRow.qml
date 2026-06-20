import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami

// Full-width slider row with left icon (tappable) — macOS style
Rectangle {
    id: row
    height: 48
    radius: 12

    required property string iconName
    required property int    value       // 0-100
    required property color  tileColor
    required property color  textColor
    required property color  sliderTrack
    required property color  accent

    readonly property bool pressed: dragArea.pressed

    signal moved(int v)
    signal iconClicked

    color: row.tileColor

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 8

        // left icon — tappable (e.g. mute toggle)
        Kirigami.Icon {
            source: row.iconName
            width: 20; height: 20
            color: row.textColor
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                onClicked: row.iconClicked()
            }
        }

        // macOS-style thin slider
        Item {
            Layout.fillWidth: true
            height: 4

            // track background
            Rectangle {
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                height: 4
                radius: 2
                color: row.sliderTrack
            }

            // filled portion
            Rectangle {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: parent.width * (row.value / 100)
                height: 4
                radius: 2
                color: row.accent

                Behavior on width { SmoothedAnimation { velocity: 300 } }
            }

            // thumb
            Rectangle {
                x: (parent.width - width) * (row.value / 100)
                anchors.verticalCenter: parent.verticalCenter
                width: 20; height: 20
                radius: 10
                color: "white"
                border.color: Qt.rgba(0,0,0,0.12)
                border.width: 1

                layer.enabled: true

                Behavior on x { SmoothedAnimation { velocity: 500 } }
            }

            // drag area
            MouseArea {
                id: dragArea
                anchors { fill: parent; margins: -12 }
                onPositionChanged: function(mouse) {
                    if (pressed) {
                        var v = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100)
                        row.moved(v)
                    }
                }
                onClicked: function(mouse) {
                    var v = Math.round(Math.max(0, Math.min(1, mouse.x / width)) * 100)
                    row.moved(v)
                }
            }
        }
    }
}
