import QtQuick
import org.kde.kirigami as Kirigami

// Small circular icon button for Now Playing controls
Rectangle {
    id: btn
    width: 32; height: 32
    radius: 16

    property string iconName: ""
    property color  iconColor: Kirigami.Theme.textColor
    property bool   enabled: true

    signal clicked

    color: hover.containsMouse ? Qt.rgba(
        Kirigami.Theme.textColor.r,
        Kirigami.Theme.textColor.g,
        Kirigami.Theme.textColor.b, 0.12) : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    Kirigami.Icon {
        anchors.centerIn: parent
        source: btn.iconName
        width: 18; height: 18
        color: btn.enabled ? btn.iconColor
             : Qt.rgba(btn.iconColor.r, btn.iconColor.g, btn.iconColor.b, 0.3)
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.enabled
        onClicked: btn.clicked()
    }
}
