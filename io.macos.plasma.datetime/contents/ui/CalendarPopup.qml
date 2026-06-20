import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Item {
    id: calendarRoot
    implicitWidth: 280
    implicitHeight: mainCol.implicitHeight + 24

    required property var currentDate

    // Which month/year the calendar is showing
    property int viewYear:  currentDate.getFullYear()
    property int viewMonth: currentDate.getMonth()  // 0-based

    readonly property var monthNames: ["January","February","March","April","May","June",
                                       "July","August","September","October","November","December"]
    readonly property var dayNames: ["Su","Mo","Tu","We","Th","Fr","Sa"]

    // All day cells for the displayed month (including leading/trailing padding days)
    readonly property var dayCells: buildDayCells(viewYear, viewMonth)

    function buildDayCells(yr, mo) {
        var cells = []
        var first = new Date(yr, mo, 1)
        var startDow = first.getDay()  // 0=Sun
        var daysInMonth = new Date(yr, mo + 1, 0).getDate()
        var prevDays = new Date(yr, mo, 0).getDate()

        // Leading days from previous month
        for (var i = startDow - 1; i >= 0; i--) {
            cells.push({ day: prevDays - i, thisMonth: false })
        }
        // This month
        for (var d = 1; d <= daysInMonth; d++) {
            cells.push({ day: d, thisMonth: true })
        }
        // Trailing days to fill last row
        var trailing = 42 - cells.length
        for (var t = 1; t <= trailing; t++) {
            cells.push({ day: t, thisMonth: false })
        }
        return cells
    }

    function prevMonth() {
        if (viewMonth === 0) { viewMonth = 11; viewYear-- }
        else viewMonth--
    }

    function nextMonth() {
        if (viewMonth === 11) { viewMonth = 0; viewYear++ }
        else viewMonth++
    }

    Column {
        id: mainCol
        anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: 12 }
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 8

        // Big time display
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(calendarRoot.currentDate, "h:mm AP")
            font.pixelSize: 40
            font.weight: Font.Thin
            color: Kirigami.Theme.textColor
        }

        // Full date
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(calendarRoot.currentDate, "dddd, MMMM d, yyyy")
            font.pixelSize: 13
            color: Kirigami.Theme.textColor
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(Kirigami.Theme.textColor.r,
                           Kirigami.Theme.textColor.g,
                           Kirigami.Theme.textColor.b, 0.15)
        }

        // Month navigation
        RowLayout {
            width: parent.width

            PlasmaComponents.ToolButton {
                icon.name: "arrow-left"
                flat: true
                onClicked: calendarRoot.prevMonth()
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: calendarRoot.monthNames[calendarRoot.viewMonth] + " " + calendarRoot.viewYear
                font.pixelSize: 13
                font.weight: Font.Medium
                color: Kirigami.Theme.textColor
            }

            PlasmaComponents.ToolButton {
                icon.name: "arrow-right"
                flat: true
                onClicked: calendarRoot.nextMonth()
            }
        }

        // Day-of-week headers
        Grid {
            width: parent.width
            columns: 7
            columnSpacing: 0

            Repeater {
                model: calendarRoot.dayNames
                delegate: Text {
                    width: Math.floor(calendarRoot.width / 7)
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.pixelSize: 11
                    color: Qt.rgba(Kirigami.Theme.textColor.r,
                                   Kirigami.Theme.textColor.g,
                                   Kirigami.Theme.textColor.b, 0.5)
                }
            }
        }

        // Day cells
        Grid {
            width: parent.width
            columns: 7
            columnSpacing: 0
            rowSpacing: 2

            Repeater {
                model: calendarRoot.dayCells

                delegate: Item {
                    width: Math.floor(calendarRoot.width / 7)
                    height: 28

                    readonly property bool isToday:
                        modelData.thisMonth &&
                        calendarRoot.viewYear === calendarRoot.currentDate.getFullYear() &&
                        calendarRoot.viewMonth === calendarRoot.currentDate.getMonth() &&
                        modelData.day === calendarRoot.currentDate.getDate()

                    Rectangle {
                        anchors.centerIn: parent
                        width: 26; height: 26
                        radius: 13
                        color: isToday ? Kirigami.Theme.highlightColor : "transparent"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        font.pixelSize: 12
                        color: isToday ? Kirigami.Theme.highlightedTextColor
                                       : modelData.thisMonth ? Kirigami.Theme.textColor
                                       : Qt.rgba(Kirigami.Theme.textColor.r,
                                                 Kirigami.Theme.textColor.g,
                                                 Kirigami.Theme.textColor.b, 0.3)
                    }
                }
            }
        }

        Item { height: 4 }
    }
}
