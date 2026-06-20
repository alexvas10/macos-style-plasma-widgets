import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components 3.0 as PC3
import org.kde.taskmanager 0.1 as TaskManager

Item {
    id: dockIcon

    // Set by Repeater in main.qml
    required property var model
    required property int index

    // Reference to the root PlasmoidItem (for dragSource)
    property Item tasksRoot
    property real iconSize: 64

    readonly property bool isLauncher:   model.IsLauncher      || false
    readonly property bool isWindow:     model.IsWindow        || false
    readonly property bool isGroup:      model.IsGroupParent   || false
    readonly property bool isActive:     model.IsActive        || false
    readonly property bool isMinimized:  model.IsMinimized     || false

    width:  iconSize
    height: iconSize + 5

    // Dim the icon while it's the drag source
    opacity: (tasksRoot && tasksRoot.dragSource === dockIcon) ? 0.35 : 1.0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // Subtle scale-up on hover (only when nothing is being dragged)
    scale: (hoverHandler.hovered && (!tasksRoot || !tasksRoot.dragSource)) ? 1.12 : 1.0
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuint } }

    HoverHandler { id: hoverHandler }

    // ── Icon ──────────────────────────────────────────────────────────────
    Kirigami.Icon {
        id: iconImage
        source: dockIcon.model.decoration
        width:  dockIcon.iconSize
        height: dockIcon.iconSize
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        smooth: true
        active: hoverHandler.hovered
    }

    // ── Running-app dot ───────────────────────────────────────────────────
    Rectangle {
        visible: dockIcon.isWindow || dockIcon.isGroup
        width:  4
        height: 4
        radius: 2
        color: dockIcon.isActive ? "#ffffff" : Qt.rgba(1, 1, 1, 0.5)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
    }

    // ── Tooltip ───────────────────────────────────────────────────────────
    PC3.ToolTip {
        text: dockIcon.model.AppName || dockIcon.model.display || ""
        visible: hoverHandler.hovered && (!tasksRoot || !tasksRoot.dragSource) && !contextMenu.visible
        delay: 600
    }

    // ── Drag ─────────────────────────────────────────────────────────────
    // dragItem carries the MIME payload that the DropArea in main.qml
    // will detect, enabling live reordering while the user drags.
    Item {
        id: dragItem
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
        Drag.onDragFinished: {
            if (dockIcon.tasksRoot && dockIcon.tasksRoot.dragSource === dockIcon) {
                dockIcon.tasksRoot.dragSource = null
            }
        }
    }

    DragHandler {
        id: dragHandler
        target: null   // item stays in place; DropArea handles ordering

        onActiveChanged: {
            if (active) {
                iconImage.grabToImage(result => {
                    if (!dragHandler.active) return
                    dragItem.Drag.imageSource = result.url
                    dragItem.Drag.mimeData = {
                        // Standard taskmanager MIME so MouseHandler / our DropArea
                        // recognises this as an internal task drag
                        "application/x-orgkdeplasmataskmanager_taskbuttonitem": String(dockIcon.index)
                    }
                    dragItem.Drag.active = true
                    if (dockIcon.tasksRoot) dockIcon.tasksRoot.dragSource = dockIcon
                })
            } else {
                dragItem.Drag.active = false
                if (dockIcon.tasksRoot && dockIcon.tasksRoot.dragSource === dockIcon) {
                    dockIcon.tasksRoot.dragSource = null
                }
            }
        }
    }

    // ── Left-click: activate / launch / cycle group ───────────────────────
    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            var groupIdx = tasksModel.makeModelIndex(dockIcon.index)
            var childCount = tasksModel.rowCount(groupIdx)

            if (childCount <= 1) {
                if (dockIcon.isMinimized) tasksModel.requestToggleMinimized(groupIdx)
                tasksModel.requestActivate(groupIdx)
                return
            }

            // Cycle to the next child window
            var activeChild = -1
            for (var j = 0; j < childCount; j++) {
                var cIdx = tasksModel.makeModelIndex(dockIcon.index, j)
                if (tasksModel.data(cIdx, TaskManager.AbstractTasksModel.IsActive)) {
                    activeChild = j
                    break
                }
            }
            var next = tasksModel.makeModelIndex(dockIcon.index, (activeChild + 1) % childCount)
            if (tasksModel.data(next, TaskManager.AbstractTasksModel.IsMinimized)) {
                tasksModel.requestToggleMinimized(next)
            }
            tasksModel.requestActivate(next)
        }
    }

    // ── Right-click: context menu ─────────────────────────────────────────
    TapHandler {
        acceptedButtons: Qt.RightButton
        gesturePolicy: TapHandler.WithinBounds
        onTapped: contextMenu.popup()
    }

    QQC2.Menu {
        id: contextMenu

        // Pin / unpin
        QQC2.MenuItem {
            text: dockIcon.isLauncher ? "Remove from Dock" : "Keep in Dock"
            icon.name: dockIcon.isLauncher ? "window-unpin" : "window-pin"
            onTriggered: {
                var idx = tasksModel.makeModelIndex(dockIcon.index)
                var url = tasksModel.data(idx, TaskManager.AbstractTasksModel.LauncherUrlWithoutIcon)
                if (!url) return
                if (dockIcon.isLauncher) {
                    tasksModel.requestRemoveLauncher(url)
                } else {
                    tasksModel.requestAddLauncher(url)
                }
                tasksModel.syncLaunchers()
            }
        }

        QQC2.MenuSeparator {}

        QQC2.MenuItem {
            text: "Open New Window"
            icon.name: "window-new"
            onTriggered: tasksModel.requestNewInstance(tasksModel.makeModelIndex(dockIcon.index))
        }

        QQC2.MenuItem {
            text: dockIcon.isGroup ? "Close All" : "Close"
            icon.name: "window-close"
            visible: dockIcon.isWindow || dockIcon.isGroup
            height: visible ? implicitHeight : 0
            onTriggered: tasksModel.requestClose(tasksModel.makeModelIndex(dockIcon.index))
        }
    }
}
