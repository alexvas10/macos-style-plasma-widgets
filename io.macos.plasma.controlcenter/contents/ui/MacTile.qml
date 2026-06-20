import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Rounded macOS-style toggle tile (WiFi, Bluetooth, etc.)
Rectangle {
    id: tile
    radius: 14

    required property bool   active
    required property string iconName
    required property string label
    required property string sublabel
    required property color  tileColor
    required property color  tileActiveColor
    required property color  textColor
    required property color  dimTextColor
    required property color  activeTextColor

    signal toggle

    color: active ? tile.tileActiveColor : tile.tileColor

    Behavior on color { ColorAnimation { duration: 150 } }

    MouseArea {
        anchors.fill: parent
        onClicked: tile.toggle()

        // ripple hint on press
        Rectangle {
            anchors.fill: parent
            radius: tile.radius
            color: parent.pressed ? Qt.rgba(0,0,0,0.08) : "transparent"
        }
    }

    Column {
        anchors { left: parent.left; bottom: parent.bottom; margins: 12 }
        spacing: 1

        // icon
        Kirigami.Icon {
            source: tile.iconName
            width: 28; height: 28
            color: tile.active ? tile.activeTextColor : tile.textColor
        }

        Item { height: 4 }

        // label
        Text {
            text: tile.label
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: tile.active ? tile.activeTextColor : tile.textColor
        }

        // sublabel
        Text {
            text: tile.sublabel
            font.pixelSize: 11
            color: tile.active
                ? Qt.rgba(tile.activeTextColor.r, tile.activeTextColor.g, tile.activeTextColor.b, 0.8)
                : tile.dimTextColor
            maximumLineCount: 1
            elide: Text.ElideRight
            width: tile.width - 24
        }
    }
}
