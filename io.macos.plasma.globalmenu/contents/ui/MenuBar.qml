import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

RowLayout {
    id: menuBar
    anchors.fill: parent
    spacing: Kirigami.Units.largeSpacing + plasmoid.configuration.menuSpacing

    required property var    menuLabels
    required property bool   menuAvailable
    required property int    currentIndex
    required property var    appMenuBridge

    Repeater {
        id: rep
        model: menuBar.menuAvailable ? menuBar.menuLabels : []

        PlasmaComponents.ToolButton {
            required property int    index
            required property string modelData

            text:          modelData
            flat:          true
            font.bold:     index === 0 && plasmoid.configuration.boldAppName
            font.pointSize: plasmoid.configuration.fontSize > 0
                            ? plasmoid.configuration.fontSize
                            : Kirigami.Theme.defaultFont.pointSize
            Layout.fillHeight: true
            checked: menuBar.currentIndex === index

            onClicked: menuBar.appMenuBridge.trigger(this, index)

            // Switch menus on hover while one is already open (macOS behavior)
            HoverHandler {
                onHoveredChanged: {
                    if (hovered && menuBar.currentIndex >= 0
                            && menuBar.currentIndex !== parent.index) {
                        menuBar.appMenuBridge.trigger(parent, parent.index)
                    }
                }
            }
        }
    }

    Item { Layout.fillWidth: true }
}
