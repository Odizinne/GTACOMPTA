import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

RowLayout {
    id: root

    property date selectedDate: new Date()
    property string placeholderText: "Select date"

    signal dateChanged(date newDate)

    function formatDate(date) {
        return Qt.formatDate(date, "yyyy-MM-dd")
    }

    TextField {
        id: dateField
        Layout.fillWidth: true
        Layout.preferredHeight: Constants.comboHeight
        text: root.formatDate(root.selectedDate)
        readOnly: true
    }

    ToolButton {
        Layout.preferredHeight: Constants.comboHeight
        icon.width: 16
        icon.height: 16
        icon.source: "qrc:/icons/date.svg"
        icon.color: Material.accent
        onClicked: datePickerDialog.open()
    }

    Dialog {
        id: datePickerDialog
        title: "Select Date"
        width: 300
        height: 350
        anchors.centerIn: parent
        modal: true
        Material.roundedScale: Material.ExtraSmallScale

        property date currentDate: root.selectedDate

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Month/Year controls
            RowLayout {
                Layout.fillWidth: true

                ToolButton {
                    text: "◀"
                    onClicked: {
                        var newDate = new Date(datePickerDialog.currentDate)
                        newDate.setMonth(newDate.getMonth() - 1)
                        datePickerDialog.currentDate = newDate
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: Qt.formatDate(datePickerDialog.currentDate, "MMMM yyyy")
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                }

                ToolButton {
                    text: "▶"
                    onClicked: {
                        var newDate = new Date(datePickerDialog.currentDate)
                        newDate.setMonth(newDate.getMonth() + 1)
                        datePickerDialog.currentDate = newDate
                    }
                }
            }

            // Day of week headers
            DayOfWeekRow {
                Layout.fillWidth: true

                delegate: Label {
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
                month: datePickerDialog.currentDate.getMonth()
                year: datePickerDialog.currentDate.getFullYear()

                delegate: Rectangle {
                    width: monthGrid.cellWidth
                    height: monthGrid.cellHeight
                    color: {
                        if (!model.today && model.month !== monthGrid.month)
                            return "transparent"
                        if (model.today && isSameDate(model.date, root.selectedDate))
                            return Material.accent
                        if (model.today)
                            return Material.color(Material.Blue, Material.Shade200)
                        if (isSameDate(model.date, root.selectedDate))
                            return Material.accent
                        return dayMouseArea.containsMouse ? Material.color(Material.Grey, Material.Shade700) : "transparent"
                    }

                    border.color: model.today ? Material.accent : "transparent"
                    border.width: model.today ? 1 : 0
                    radius: 4

                    function isSameDate(date1, date2) {
                        return date1.getDate() === date2.getDate() &&
                               date1.getMonth() === date2.getMonth() &&
                               date1.getFullYear() === date2.getFullYear()
                    }

                    Label {
                        anchors.centerIn: parent
                        text: model.day
                        color: {
                            if (!model.today && model.month !== monthGrid.month)
                                return Material.hintTextColor
                            if (isSameDate(model.date, root.selectedDate))
                                return Material.primaryTextColor
                            return Material.foreground
                        }
                        font.bold: model.today || isSameDate(model.date, root.selectedDate)
                    }

                    MouseArea {
                        id: dayMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.selectedDate = model.date
                            root.dateChanged(model.date)
                            dateField.text = root.formatDate(model.date)
                            datePickerDialog.close()
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
                    datePickerDialog.currentDate = today
                    root.dateChanged(today)
                    dateField.text = root.formatDate(today)
                    datePickerDialog.close()
                }
            }

            Button {
                flat: true
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: datePickerDialog.close()
            }
        }
    }
}
