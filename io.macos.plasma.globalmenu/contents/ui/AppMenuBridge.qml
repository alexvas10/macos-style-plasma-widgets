import QtQuick
import org.kde.plasma.plasma5support as P5Support

Item {
    id: bridge

    // Input: PID of the active window (replaces the broken TasksModel service-name roles)
    property int appPid: 0

    // Output
    property bool   menuAvailable: false
    property var    menuItems:     []
    property var    menuLabels:    []
    property var    menuIds:       []
    property int    currentIndex:  -1

    // Emitted when submenu children are ready for a given top-level item index
    signal submenuReady(int forIndex, var items)
    // Emitted when a nested submenu drill-down is ready
    signal nestedSubmenuReady(var items)
    // Emitted when discovery or fetch completes with no menu found
    signal menuNotFound()

    readonly property string helperPath:
        Qt.resolvedUrl("get_menu_labels.py").toString().replace(/^file:\/\//, "")

    // Internally discovered service + path for the current PID
    property string _svc:  ""
    property string _path: ""
    property int    _discoverSeq:    0
    property int    _fetchSeq:       0
    property int    _openedItemId:   -1

    onAppPidChanged: {
        _svc  = ""
        _path = ""
        menuAvailable = false
        menuItems = []; menuLabels = []; menuIds = []
        currentIndex = -1
        if (appPid > 0) {
            _discoverSeq++
            var seq = _discoverSeq
            discoverExec.run(
                "python3 " + helperPath + " pid " + appPid + " # " + seq
            )
        }
    }

    // ── Discovery: PID → service + path ──────────────────────────────────────
    P5Support.DataSource {
        id: discoverExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var stdout = (data["stdout"] || "").trim()
            disconnectSource(sourceName)
            if (stdout && stdout !== "{}") {
                try {
                    var result = JSON.parse(stdout)
                    if (result.service && result.path) {
                        bridge._svc  = result.service
                        bridge._path = result.path
                        bridge._doFetchLayout()
                        return
                    }
                } catch(e) {}
            }
            // No dbusmenu found for this PID — stay on fallback
            bridge._svc = ""
            bridge._path = ""
            bridge.menuAvailable = false
            bridge.menuNotFound()
        }
        function run(cmd) { connectSource(cmd) }
    }

    // ── Top-level layout fetch ────────────────────────────────────────────────
    P5Support.DataSource {
        id: fetchExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var stdout = (data["stdout"] || "").trim()
            disconnectSource(sourceName)
            if (stdout && stdout !== "[]") {
                try {
                    var items = JSON.parse(stdout)
                    if (Array.isArray(items) && items.length > 0) {
                        bridge.menuItems    = items
                        bridge.menuLabels   = items.map(function(i){ return i.label })
                        bridge.menuIds      = items.map(function(i){ return i.id })
                        bridge.menuAvailable = true
                        return
                    }
                } catch(e) {}
            }
            bridge.menuItems    = []
            bridge.menuLabels   = []
            bridge.menuIds      = []
            bridge.menuAvailable = false
            bridge.menuNotFound()
        }
        function run(cmd) { connectSource(cmd) }
    }

    // ── Submenu children fetch ────────────────────────────────────────────────
    P5Support.DataSource {
        id: submenuExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            var stdout = (data["stdout"] || "").trim()
            disconnectSource(sourceName)
            var items = []
            if (stdout && stdout !== "[]") {
                try { items = JSON.parse(stdout) } catch(e) {}
            }
            // idx=-2 marks a nested drill-down; any other value is a top-level open.
            // Read forIndex from the command string, not bridge.currentIndex.
            // currentIndex is reset to -1 by onAppPidChanged (triggered when the
            // panel briefly gets focus during a menu switch), so reading it at
            // callback time gives -1 and onSubmenuReady silently returns early.
            var m = sourceName.match(/# idx=(-?\d+)/)
            var forIndex = m ? parseInt(m[1]) : bridge.currentIndex
            if (forIndex === -2) {
                bridge.nestedSubmenuReady(items)
            } else {
                bridge.submenuReady(forIndex, items)
            }
        }
        function run(cmd) { connectSource(cmd) }
    }

    // ── Activate (clicked event) ──────────────────────────────────────────────
    P5Support.DataSource {
        id: activateExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) { disconnectSource(sourceName) }
        function run(cmd) { connectSource(cmd) }
    }

    // ── Close (closed event) ──────────────────────────────────────────────────
    P5Support.DataSource {
        id: closeExec
        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) { disconnectSource(sourceName) }
        function run(cmd) { connectSource(cmd) }
    }

    function _doFetchLayout() {
        if (_svc === "" || _path === "") return
        fetchExec.run("python3 " + helperPath + " " + _svc + " " + _path)
    }

    function fetchSubmenu(displayIndex) {
        var menuIndex = displayIndex - 1
        if (menuIndex < 0 || menuIndex >= menuIds.length) return
        var itemId = menuIds[menuIndex]
        // Send close for previously opened submenu before opening a new one
        if (_openedItemId >= 0 && _openedItemId !== itemId) {
            closeExec.run(
                "python3 " + helperPath +
                " " + _svc + " " + _path +
                " close " + _openedItemId
            )
        }
        _openedItemId = itemId
        currentIndex = displayIndex
        _fetchSeq++
        // Embed displayIndex in the command comment so onNewData can recover it
        // even if currentIndex is reset by an intermediate onAppPidChanged.
        submenuExec.run(
            "python3 " + helperPath +
            " " + _svc +
            " " + _path +
            " children " + itemId +
            " # idx=" + displayIndex + "," + _fetchSeq
        )
    }

    function activateItem(itemId) {
        currentIndex = -1
        var svc  = _svc
        var path = _path
        var openedId = _openedItemId
        _openedItemId = -1
        activateExec.run(
            "python3 " + helperPath +
            " " + svc + " " + path +
            " activate " + itemId
        )
        // Send closed for the parent submenu after activation
        if (openedId >= 0) {
            closeExec.run(
                "python3 " + helperPath +
                " " + svc + " " + path +
                " close " + openedId
            )
        }
    }

    function fetchNestedSubmenu(itemId) {
        _fetchSeq++
        submenuExec.run(
            "python3 " + helperPath +
            " " + _svc + " " + _path +
            " children " + itemId +
            " # idx=-2," + _fetchSeq
        )
    }

    function closeMenu() {
        currentIndex = -1
        if (_openedItemId >= 0 && _svc !== "") {
            closeExec.run(
                "python3 " + helperPath +
                " " + _svc + " " + _path +
                " close " + _openedItemId
            )
        }
        _openedItemId = -1
    }
}
