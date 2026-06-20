import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents

// A single top-level menu entry in the macOS-style menu bar.
// index 0 is the bold app name; subsequent indices are menu categories (File, Edit…).
Item {
    id: menuButton

    required property int    buttonIndex
    required property string menuLabel
    required property bool   isAppName
    required property bool   menuOpen

    signal activated()

    property bool hovered: hoverHandler.hovered

    implicitWidth:  labelText.implicitWidth + Kirigami.Units.largeSpacing * 2
    implicitHeight: Kirigami.Units.gridUnit * 2

    // macOS-style highlight: subtle rounded rect
    Rectangle {
        anchors {
            fill:           parent
            topMargin:      3
            bottomMargin:   3
            leftMargin:     1
            rightMargin:    1
        }
        radius: 4
        color: (menuButton.menuOpen || menuButton.hovered)
               ? Qt.rgba(Kirigami.Theme.highlightColor.r,
                         Kirigami.Theme.highlightColor.g,
                         Kirigami.Theme.highlightColor.b,
                         0.18)
               : "transparent"

        Behavior on color {
            ColorAnimation { duration: 80 }
        }
    }

    PlasmaComponents.Label {
        id:               labelText
        anchors.centerIn: parent
        text:             menuButton.menuLabel
        font.bold:        menuButton.isAppName && plasmoid.configuration.boldAppName
        font.pointSize:   plasmoid.configuration.fontSize > 0
                          ? plasmoid.configuration.fontSize
                          : Kirigami.Theme.defaultFont.pointSize
        color:            Kirigami.Theme.textColor
        elide:            Text.ElideRight
    }

    HoverHandler {
        id: hoverHandler

        // While a menu is open elsewhere, hovering another button switches it (macOS behavior)
        onHoveredChanged: {
            if (hovered && !menuButton.menuOpen && menuButton.buttonIndex !== -1) {
                // Check if any sibling has its menu open by looking at parent's currentIndex
                var bar = menuButton.parent
                if (bar && bar.currentIndex !== undefined && bar.currentIndex >= 0
                        && bar.currentIndex !== menuButton.buttonIndex) {
                    menuButton.activated()
                }
            }
        }
    }

    TapHandler {
        onTapped: menuButton.activated()
    }
}
