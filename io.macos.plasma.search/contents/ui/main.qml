import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    P5Support.DataSource {
        id: runner
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)
    }

    compactRepresentation: Item {
        Layout.preferredWidth: 28
        Layout.fillHeight: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            // KDE registers krunner as a DBus-activated service;
            // opening its .desktop file via KIO launches it cleanly.
            onClicked: runner.connectSource("qdbus6 org.kde.krunner /App org.kde.krunner.App.display")

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: parent.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            }

            Kirigami.Icon {
                anchors.centerIn: parent
                source: "search"
                width: 16
                height: 16
                color: Kirigami.Theme.textColor
            }
        }
    }

    fullRepresentation: compactRepresentation
}
