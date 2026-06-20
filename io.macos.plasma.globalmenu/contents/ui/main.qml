import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.constraintHints: Plasmoid.CanFillArea
    preferredRepresentation: fullRepresentation
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    ActiveWindowBridge { id: windowBridge }

    AppMenuBridge {
        id: appMenuBridge
        appPid: windowBridge.appPid
    }

    readonly property bool showingRealMenu:
        appMenuBridge.menuAvailable &&
        appMenuBridge.menuLabels.length > 0

    property string _syncedAppName: ""

    readonly property var displayLabels: {
        if (!showingRealMenu) return []
        return [root._syncedAppName].concat(appMenuBridge.menuLabels)
    }

    fullRepresentation: Item {
        id: fullRep
        Layout.fillWidth:  true
        Layout.fillHeight: true

        property var  _frozenLabels:   []
        property bool _menuFrozen:     false
        property int  _menuOwnerPid:   0
        property int  _freezeSeq:      0
        property var  _lastRealLabels: []
        property bool _awaitingMenu:   false
        property var  _menuStack:      []

        Timer {
            id: awaitMenuTimer
            interval: 500
            onTriggered: fullRep._awaitingMenu = false
        }

        readonly property bool activeShowingRealMenu:
            fullRep._menuFrozen || root.showingRealMenu || fullRep._awaitingMenu
        readonly property var activeLabels:
            fullRep._menuFrozen  ? fullRep._frozenLabels  :
            root.showingRealMenu ? root.displayLabels      :
            fullRep._awaitingMenu ? fullRep._lastRealLabels : []

        // Qt.Popup creates an xdg_popup Wayland surface that IS interactive.
        // PlasmaCore.Dialog in a panel context gets assigned a non-interactive
        // plasma-shell role by KWin and never receives pointer events.
        Window {
            id: appMenuDialog
            flags: Qt.Popup | Qt.FramelessWindowHint
            transientParent: root.Window.window
            width: 280
            height: appMenuList.contentHeight
            color: "transparent"
            visible: false

            onVisibleChanged: if (!visible) {
                fullRep._menuStack = []
                var seq = fullRep._freezeSeq
                Qt.callLater(function() {
                    if (fullRep._freezeSeq !== seq) return
                    fullRep._menuFrozen = false
                    if (windowBridge.appPid === 0 && fullRep._lastRealLabels.length > 0) {
                        fullRep._awaitingMenu = true
                        awaitMenuTimer.restart()
                    }
                })
            }

            Rectangle {
                anchors.fill: parent
                color: Kirigami.Theme.backgroundColor
                border.color: Qt.rgba(
                    Kirigami.Theme.textColor.r,
                    Kirigami.Theme.textColor.g,
                    Kirigami.Theme.textColor.b,
                    0.15)
                border.width: 1
                radius: Kirigami.Units.cornerRadius

                ListView {
                    id: appMenuList
                    anchors { fill: parent; margins: 1 }
                    width: 278
                    height: contentHeight
                    implicitHeight: contentHeight
                    interactive: false
                    model: []

                    header: PlasmaComponents.ItemDelegate {
                        visible: fullRep._menuStack.length > 0
                        height:  visible ? Math.round(Kirigami.Units.gridUnit * 1.6) : 0
                        width:   278
                        text:    i18n("Back")
                        icon.name: "go-previous"
                        onClicked: {
                            var stack = fullRep._menuStack.slice()
                            appMenuList.model = stack.pop()
                            fullRep._menuStack = stack
                        }
                    }

                    delegate: Item {
                        required property var  modelData
                        required property int  index

                        readonly property int itemHeight: Math.round(Kirigami.Units.gridUnit * 1.6)

                        width: appMenuList.width
                        height: modelData.type === "separator"
                                ? Kirigami.Units.smallSpacing * 2
                                : itemHeight

                        PlasmaComponents.ItemDelegate {
                            visible: modelData.type !== "separator"
                            enabled: modelData.enabled !== false
                            anchors { left: parent.left; right: parent.right; top: parent.top; bottom: parent.bottom }
                            text: modelData.label || ""
                            icon.name: modelData.has_submenu ? "go-next" : ""
                            onClicked: {
                                if (modelData.has_submenu) {
                                    appMenuBridge.fetchNestedSubmenu(modelData.id)
                                } else {
                                    var itemId = modelData.id
                                    appMenuDialog.visible = false
                                    appMenuBridge.closeMenu()
                                    appMenuBridge.activateItem(itemId)
                                }
                            }
                        }

                        Rectangle {
                            visible: modelData.type === "separator"
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
        }

        Connections {
            target: windowBridge
            function onAppPidChanged() {
                if (windowBridge.appPid > 0) {
                    if (windowBridge.appPid !== fullRep._menuOwnerPid) {
                        appMenuDialog.visible = false
                        appMenuBridge.closeMenu()
                        fullRep._menuFrozen = false
                    }
                    if (fullRep._lastRealLabels.length > 0) {
                        fullRep._awaitingMenu = true
                        awaitMenuTimer.restart()
                    }
                }
            }
        }

        Connections {
            target: appMenuBridge

            function onMenuLabelsChanged() {
                if (appMenuBridge.menuLabels.length > 0) {
                    root._syncedAppName = windowBridge.activeAppName
                    fullRep._lastRealLabels = [windowBridge.activeAppName]
                                              .concat(appMenuBridge.menuLabels)
                    fullRep._awaitingMenu = false
                    awaitMenuTimer.stop()
                }
            }

            function onMenuNotFound() {
                fullRep._awaitingMenu = false
                awaitMenuTimer.stop()
            }

            function onNestedSubmenuReady(items) {
                var stack = fullRep._menuStack.slice()
                stack.push(appMenuList.model)
                fullRep._menuStack = stack
                appMenuList.model = items
            }

            function onSubmenuReady(forIndex, items) {
                if (!fullRep._menuFrozen) fullRep._frozenLabels = root.displayLabels
                fullRep._menuOwnerPid = windowBridge.appPid || fullRep._menuOwnerPid
                fullRep._menuFrozen   = true

                var btn = buttonRepeater.itemAt(forIndex)
                if (!btn) return

                fullRep._menuStack = []
                appMenuList.model  = items

                // Position the popup below the clicked button.
                // mapToGlobal converts the button's bottom-left to screen coordinates.
                var pos = btn.mapToGlobal(0, btn.height)
                appMenuDialog.x = pos.x
                appMenuDialog.y = pos.y

                appMenuDialog.visible = false
                fullRep._freezeSeq++
                Qt.callLater(function() { appMenuDialog.visible = true })
            }
        }

        RowLayout {
            anchors.fill: parent
            visible:  fullRep.activeShowingRealMenu
            spacing:  Kirigami.Units.largeSpacing + plasmoid.configuration.menuSpacing

            Repeater {
                id: buttonRepeater
                model: fullRep.activeLabels

                PlasmaComponents.ToolButton {
                    id: menuBtn
                    required property int    index
                    required property string modelData

                    text:              modelData
                    flat:              true
                    font.bold:         index === 0 && plasmoid.configuration.boldAppName
                    font.pointSize:    plasmoid.configuration.fontSize > 0
                                       ? plasmoid.configuration.fontSize
                                       : Kirigami.Theme.defaultFont.pointSize
                    Layout.fillHeight: true
                    checked: appMenuBridge.currentIndex === index && index > 0

                    onClicked: {
                        if (index === 0) return
                        if (appMenuDialog.visible && appMenuBridge.currentIndex === index) {
                            appMenuDialog.visible = false
                            appMenuBridge.closeMenu()
                            return
                        }
                        if (appMenuDialog.visible) {
                            appMenuDialog.visible = false
                            fullRep._freezeSeq++
                        }
                        appMenuBridge.fetchSubmenu(index)
                    }

                    HoverHandler {
                        onHoveredChanged: {
                            if (hovered && appMenuDialog.visible
                                    && appMenuBridge.currentIndex > 0
                                    && appMenuBridge.currentIndex !== menuBtn.index
                                    && menuBtn.index > 0) {
                                appMenuDialog.visible = false
                                fullRep._freezeSeq++
                                appMenuBridge.fetchSubmenu(menuBtn.index)
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        Loader {
            anchors.fill: parent
            active:  !fullRep.activeShowingRealMenu
            visible: active
            sourceComponent: FallbackMenuBar {
                appName: windowBridge.activeAppName || "Finder"
            }
        }
    }
}
