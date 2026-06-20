import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.clock as PlasmaClk
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    preferredRepresentation: compactRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    // Native Plasma 6 clock — updates every second, respects system timezone
    PlasmaClk.Clock {
        id: clock
        trackSeconds: true
    }

    readonly property var  now:        clock.dateTime
    readonly property string timeStr:  Qt.formatTime(now, "h:mm AP")
    readonly property string dateStr:  Qt.formatDate(now, "ddd MMM d")

    PlasmaCore.Dialog {
        id: calendarDialog
        visible: false
        flags: Qt.WindowDoesNotAcceptFocus
        location: PlasmaCore.Types.TopEdge

        mainItem: CalendarPopup {
            currentDate: root.now
        }
    }

    compactRepresentation: Item {
        id: compactItem
        Layout.preferredWidth: dateTimeRow.implicitWidth + 16
        Layout.fillHeight: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                if (calendarDialog.visible) {
                    calendarDialog.visible = false
                } else {
                    calendarDialog.visualParent = compactItem
                    Qt.callLater(function() { calendarDialog.visible = true })
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: parent.containsMouse || calendarDialog.visible
                       ? Qt.rgba(1, 1, 1, 0.15) : "transparent"
            }

            Row {
                id: dateTimeRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.dateStr
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.timeStr
                    color: Kirigami.Theme.textColor
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }
            }
        }
    }

    fullRepresentation: compactRepresentation
}
