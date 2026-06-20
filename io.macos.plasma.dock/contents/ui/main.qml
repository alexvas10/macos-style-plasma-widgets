import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.taskmanager 0.1 as TaskManager

PlasmoidItem {
    id: tasks

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property int padH: 12
    readonly property int padV: 3

    // Which DockIcon is currently being dragged (null when idle)
    property Item dragSource: null

    onDragSourceChanged: {
        if (!dragSource) {
            tasksModel.syncLaunchers()
        }
    }

    TaskManager.TasksModel {
        id: tasksModel
        sortMode: TaskManager.TasksModel.SortManual
        filterByScreen: false
        launcherList: Plasmoid.configuration.launchers

        onLauncherListChanged: {
            Plasmoid.configuration.launchers = launcherList
        }
    }

    fullRepresentation: Item {
        id: dockRoot

        readonly property real iconSize: Math.max(16, height - tasks.padV * 2 - 5)

        Layout.preferredWidth: iconsRow.width + tasks.padH * 2
        Layout.preferredHeight: height
        implicitWidth: Layout.preferredWidth
        implicitHeight: Layout.preferredHeight

        // DropArea enables live reordering: as the dragged icon passes over
        // a neighbour the model move fires immediately (same as icontasks).
        DropArea {
            id: dropArea
            anchors.fill: parent

            property var ignoredItem: null

            onEntered: event => {
                // Reject panel-widget drops so they fall through
                if (event.formats.indexOf("text/x-plasmoidservicename") >= 0) {
                    event.accepted = false
                }
            }

            onPositionChanged: event => {
                if (!tasks.dragSource) return
                var localPos = iconsRow.mapFromItem(dropArea, event.x, event.y)
                var above = iconsRow.childAt(localPos.x, localPos.y)
                if (!above || above === tasks.dragSource || above === dropArea.ignoredItem) return
                var fromIdx = tasks.dragSource.index
                var toIdx   = above.index
                if (fromIdx === undefined || toIdx === undefined || fromIdx === toIdx) return
                tasksModel.move(fromIdx, toIdx)
                dropArea.ignoredItem = above
                ignoreTimer.restart()
            }

            onExited: {
                dropArea.ignoredItem = null
                ignoreTimer.stop()
            }

            Timer {
                id: ignoreTimer
                interval: 750
                repeat: false
                onTriggered: dropArea.ignoredItem = null
            }

            Connections {
                target: tasks
                function onDragSourceChanged() {
                    if (!tasks.dragSource) {
                        dropArea.ignoredItem = null
                        ignoreTimer.stop()
                    }
                }
            }
        }

        Row {
            id: iconsRow
            anchors.centerIn: parent
            spacing: 8
            height: dockRoot.height

            Repeater {
                model: tasksModel

                DockIcon {
                    iconSize:  dockRoot.iconSize
                    tasksRoot: tasks
                }
            }
        }
    }
}
