import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

RowLayout {
    id: fallbackBar
    anchors.fill: parent
    spacing: Kirigami.Units.largeSpacing + plasmoid.configuration.menuSpacing

    property string appName: "Finder"
    property var _menuItems: []

    P5Support.DataSource {
        id: exec
        engine: "executable"
        connectedSources: []
        onNewData: disconnectSource(sourceName)
        function run(cmd) { connectSource(cmd) }
    }

    // Inject a keyboard shortcut into the focused app.
    // Tries xdotool (X11) then ydotool (Wayland).
    function sendKey(combo) {
        exec.run("xdotool key --clearmodifiers " + combo +
                 " 2>/dev/null || ydotool key " + combo + " 2>/dev/null")
    }

    // Show the shared dialog anchored below btn, populated with items.
    // Qt.callLater gives QML one frame to measure content before the window appears.
    function showMenu(btn, items) {
        menuDialog.visible = false
        fallbackBar._menuItems = items
        menuDialog.visualParent = btn
        Qt.callLater(function() { menuDialog.visible = true })
    }

    // PlasmaCore.Dialog creates a real KWin popup window that escapes panel clipping.
    // mainItem is a ListView so implicitHeight: contentHeight updates reactively.
    PlasmaCore.Dialog {
        id: menuDialog
        location: PlasmaCore.Types.TopEdge
        visible: false
        hideOnWindowDeactivate: true

        mainItem: ListView {
            id: menuList
            width: 260
            implicitWidth: 260
            implicitHeight: contentHeight
            model: fallbackBar._menuItems

            delegate: Item {
                width: menuList.width
                height: modelData.isSep
                        ? Kirigami.Units.smallSpacing * 2
                        : itemDel.implicitHeight

                PlasmaComponents.ItemDelegate {
                    id: itemDel
                    visible: !modelData.isSep
                    anchors { left: parent.left; right: parent.right }
                    text: modelData.label || ""
                    onClicked: {
                        if (modelData.key) fallbackBar.sendKey(modelData.key)
                        if (modelData.cmd) exec.run(modelData.cmd)
                        menuDialog.visible = false
                    }
                }

                Rectangle {
                    visible: modelData.isSep
                    anchors {
                        left: parent.left; right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: Kirigami.Units.largeSpacing
                        rightMargin: Kirigami.Units.largeSpacing
                    }
                    height: 1
                    color: Kirigami.Theme.textColor
                    opacity: 0.2
                }
            }
        }
    }

    PlasmaComponents.Label {
        text: fallbackBar.appName
        font.bold: plasmoid.configuration.boldAppName
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize
                        : Kirigami.Theme.defaultFont.pointSize
        leftPadding:  Kirigami.Units.largeSpacing
        rightPadding: Kirigami.Units.largeSpacing
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
    }

    PlasmaComponents.ToolButton {
        id: fileBtn; text: "File"; flat: true; Layout.fillHeight: true
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize : Kirigami.Theme.defaultFont.pointSize
        onClicked: fallbackBar.showMenu(fileBtn, [
            {label: "New",           key: "ctrl+n"},
            {label: "Open…",         key: "ctrl+o"},
            {isSep: true},
            {label: "Save",          key: "ctrl+s"},
            {label: "Save As…",      key: "ctrl+shift+s"},
            {isSep: true},
            {label: "Close Window",  key: "ctrl+w"},
            {label: "Quit",          key: "ctrl+q"},
        ])
    }

    PlasmaComponents.ToolButton {
        id: editBtn; text: "Edit"; flat: true; Layout.fillHeight: true
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize : Kirigami.Theme.defaultFont.pointSize
        onClicked: fallbackBar.showMenu(editBtn, [
            {label: "Undo",       key: "ctrl+z"},
            {label: "Redo",       key: "ctrl+shift+z"},
            {isSep: true},
            {label: "Cut",        key: "ctrl+x"},
            {label: "Copy",       key: "ctrl+c"},
            {label: "Paste",      key: "ctrl+v"},
            {isSep: true},
            {label: "Select All", key: "ctrl+a"},
            {label: "Find…",      key: "ctrl+f"},
        ])
    }

    PlasmaComponents.ToolButton {
        id: viewBtn; text: "View"; flat: true; Layout.fillHeight: true
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize : Kirigami.Theme.defaultFont.pointSize
        onClicked: fallbackBar.showMenu(viewBtn, [
            {label: "Toggle Full Screen", key: "F11"},
            {isSep: true},
            {label: "Zoom In",            key: "ctrl+plus"},
            {label: "Zoom Out",           key: "ctrl+minus"},
            {label: "Reset Zoom",         key: "ctrl+0"},
        ])
    }

    PlasmaComponents.ToolButton {
        id: goBtn; text: "Go"; flat: true; Layout.fillHeight: true
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize : Kirigami.Theme.defaultFont.pointSize
        onClicked: fallbackBar.showMenu(goBtn, [
            {label: "Home",      cmd: "dolphin ~"},
            {label: "Desktop",   cmd: "dolphin ~/Desktop"},
            {label: "Downloads", cmd: "dolphin ~/Downloads"},
            {label: "Documents", cmd: "dolphin ~/Documents"},
            {isSep: true},
            {label: "Network",   cmd: "dolphin remote:/"},
        ])
    }

    PlasmaComponents.ToolButton {
        id: windowBtn; text: "Window"; flat: true; Layout.fillHeight: true
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize : Kirigami.Theme.defaultFont.pointSize
        onClicked: fallbackBar.showMenu(windowBtn, [
            {label: "Minimize", cmd: "qdbus org.kde.KWin /KWin slotWindowMinimize"},
            {label: "Maximize", cmd: "qdbus org.kde.KWin /KWin slotWindowMaximize"},
            {isSep: true},
            {label: "Close",    cmd: "qdbus org.kde.KWin /KWin slotWindowClose"},
        ])
    }

    PlasmaComponents.ToolButton {
        id: helpBtn; text: "Help"; flat: true; Layout.fillHeight: true
        font.pointSize: plasmoid.configuration.fontSize > 0
                        ? plasmoid.configuration.fontSize : Kirigami.Theme.defaultFont.pointSize
        onClicked: fallbackBar.showMenu(helpBtn, [
            {label: "KDE Help Center",   cmd: "khelpcenter"},
            {isSep: true},
            {label: "About KDE Plasma…", cmd: "systemsettings kcm_about-distro"},
        ])
    }

    Item { Layout.fillWidth: true }
}
