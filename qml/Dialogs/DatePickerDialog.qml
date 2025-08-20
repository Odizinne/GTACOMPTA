pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: "Select Date"
    width: 300
    height: 350
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property date selectedDate: new Date()
    property date currentDate: selectedDate

    signal dateSelected(date newDate)

    function isSameDate(date1, date2) {
        if (!date1 || !date2) return false
        var d1 = new Date(date1)
        var d2 = new Date(date2)
        return d1.getDate() === d2.getDate() &&
               d1.getMonth() === d2.getMonth() &&
               d1.getFullYear() === d2.getFullYear()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Month/Year controls
        RowLayout {
            Layout.fillWidth: true

            ToolButton {
                text: "◀"
                onClicked: {
                    var newDate = new Date(root.currentDate)
                    newDate.setMonth(newDate.getMonth() - 1)
                    root.currentDate = newDate
                }
            }

            Label {
                Layout.fillWidth: true
                text: Qt.formatDate(root.currentDate, "MMMM yyyy")
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
            }

            ToolButton {
                text: "▶"
                onClicked: {
                    var newDate = new Date(root.currentDate)
                    newDate.setMonth(newDate.getMonth() + 1)
                    root.currentDate = newDate
                }
            }
        }

        // Day of week headers
        DayOfWeekRow {
            Layout.fillWidth: true

            delegate: Label {
                required property var model
                text: model.shortName
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                font.pixelSize: 12
                color: Material.accent
            }
        }

        // Month grid
        MonthGrid {
            id: monthGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: root.currentDate.getMonth()
            year: root.currentDate.getFullYear()

            delegate: Rectangle {
                id: delRec
                required property var model
                width: monthGrid.width / 7
                height: monthGrid.height / 6
                color: {
                    if (!model.today && model.month !== monthGrid.month)
                        return "transparent"
                    if (model.today && root.isSameDate(model.date, root.selectedDate))
                        return Material.accent
                    if (model.today)
                        return Material.color(Material.Blue, Material.Shade200)
                    if (root.isSameDate(model.date, root.selectedDate))
                        return Material.accent
                    return dayMouseArea.containsMouse ? Material.color(Material.Grey, Material.Shade700) : "transparent"
                }

                border.color: model.today ? Material.accent : "transparent"
                border.width: model.today ? 1 : 0
                radius: 4

                Label {
                    anchors.centerIn: parent
                    text: delRec.model.day
                    color: {
                        if (!delRec.model.today && delRec.model.month !== monthGrid.month)
                            return Material.hintTextColor
                        if (root.isSameDate(delRec.model.date, root.selectedDate))
                            return Material.primaryTextColor
                        return Material.foreground
                    }
                    font.bold: delRec.model.today || root.isSameDate(delRec.model.date, root.selectedDate)
                }

                MouseArea {
                    id: dayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selectedDate = delRec.model.date
                        root.dateSelected(delRec.model.date)
                        root.close()
                    }
                }
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Today"
            onClicked: {
                var today = new Date()
                root.selectedDate = today
                root.currentDate = today
                root.dateSelected(today)
                root.close()
            }
        }

        Button {
            flat: true
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.close()
        }
    }
}
