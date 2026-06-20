import QtQuick
import org.kde.taskmanager as TaskManager

// Tracks the active window and exposes its app name and appmenu D-Bus info.
// Pattern follows com.github.antroids.application-title-bar/ActiveTasksModel.qml.
Item {
    id: bridge

    property string activeAppName:     ""
    property string menuServiceName:   ""   // kept but empty on Wayland — use appPid instead
    property string menuObjectPath:    ""
    property bool   hasActiveWindow:   false
    property bool   hasAppMenu:        false
    property int    appPid:            0
    property var    windowId:          0
    property int    taskCount:         tasksModel.count   // debug

    // Filled by the sub-objects below
    property var activeTaskIndex: tasksModel.index(-1, -1)

    TaskManager.VirtualDesktopInfo { id: vdInfo }
    TaskManager.ActivityInfo       { id: actInfo }

    TaskManager.TasksModel {
        id: tasksModel

        sortMode:               TaskManager.TasksModel.SortLastActivated
        groupMode:              TaskManager.TasksModel.GroupDisabled
        filterByVirtualDesktop: true
        filterByActivity:       true
        filterByScreen:         false   // temporarily disabled to diagnose screen-filter issue
        filterHidden:           true
        screenGeometry:         plasmoid.containment.screenGeometry
        activity:               actInfo.currentActivity
        virtualDesktop:         vdInfo.currentDesktop

        onActiveTaskChanged:    Qt.callLater(bridge.update)
        onDataChanged:          Qt.callLater(bridge.update)
        onCountChanged:         Qt.callLater(bridge.update)
    }

    function update() {
        var idx = tasksModel.activeTask

        // No active task at all
        if (!idx || !idx.valid) {
            activeTaskIndex  = tasksModel.index(-1, -1)
            hasActiveWindow  = false
            activeAppName    = ""
            menuServiceName  = ""
            menuObjectPath   = ""
            hasAppMenu       = false
            appPid           = 0
            return
        }

        activeTaskIndex = idx
        hasActiveWindow = true

        // App display name — prefer AppName, fall back to window title
        var name = tasksModel.data(idx, TaskManager.AbstractTasksModel.AppName)
        if (!name || name === "") {
            name = tasksModel.data(idx, TaskManager.AbstractTasksModel.Display) || ""
        }
        activeAppName = name

        // PID — used by AppMenuBridge to discover the dbusmenu service.
        // ApplicationMenuServiceName is empty on Wayland when no system appmenu
        // applet is registered, so we do our own PID-based discovery instead.
        var pid = tasksModel.data(idx, TaskManager.AbstractTasksModel.AppPid) || 0
        appPid  = pid

        // Window ID — can be used for more precise mapping if needed
        var winIds = tasksModel.data(idx, TaskManager.AbstractTasksModel.WinIdList)
        windowId = (winIds && winIds.length > 0) ? winIds[0] : 0

        // Keep these for potential future use; empty on current Wayland setup
        var svc  = tasksModel.data(idx, TaskManager.AbstractTasksModel.ApplicationMenuServiceName) || ""
        var path = tasksModel.data(idx, TaskManager.AbstractTasksModel.ApplicationMenuObjectPath) || ""
        menuServiceName = svc
        menuObjectPath  = path
        hasAppMenu      = (svc !== "" && path !== "")
    }

    Component.onCompleted: update()
}
