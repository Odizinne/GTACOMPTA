import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Column {
    spacing: 0

    ToolBar {
        width: parent.width
        height: 35

        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 10

            SortableLabel {
                headerText: "Name"
                sortColumn: EmployeeModel.SortByName
                sortModel: AppState.employeeModel
                Layout.preferredWidth: 120
            }

            SortableLabel {
                headerText: "Phone"
                sortColumn: EmployeeModel.SortByPhone
                sortModel: AppState.employeeModel
                Layout.preferredWidth: 100
            }

            SortableLabel {
                headerText: "Role"
                sortColumn: EmployeeModel.SortByRole
                sortModel: AppState.employeeModel
                Layout.preferredWidth: 100
            }

            SortableLabel {
                headerText: "Salary"
                sortColumn: EmployeeModel.SortBySalary
                sortModel: AppState.employeeModel
                Layout.preferredWidth: 80
            }

            SortableLabel {
                headerText: "Added Date"
                sortColumn: EmployeeModel.SortByAddedDate
                sortModel: AppState.employeeModel
                Layout.preferredWidth: 90
            }

            SortableLabel {
                headerText: "Comment"
                sortColumn: EmployeeModel.SortByComment
                sortModel: AppState.employeeModel
                Layout.fillWidth: true
            }

            Label {
                text: "Actions"
                font.bold: true
            }
        }
    }

    ScrollView {
        width: parent.width
        height: parent.height - 35

        ListView {
            id: employeeListView
            width: parent.width
            height: parent.parent.height
            model: AppState.employeeFilterModel
            spacing: 0

            Label {
                anchors.centerIn: parent
                text: AppState.filterText ? "No employees match the filter." : "No employees added yet.\nUse Databases → New Employee to add one."
                visible: employeeListView.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: "gray"
            }

            delegate: Rectangle {
                width: employeeListView.width
                height: 40
                color: (index % 2 === 0) ? "#404040" : "#303030"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    spacing: 10

                    Label {
                        text: name
                        font.bold: true
                        Layout.preferredWidth: 120
                        elide: Text.ElideRight
                    }

                    Label {
                        text: phone
                        Layout.preferredWidth: 100
                        elide: Text.ElideRight
                    }

                    Label {
                        text: role
                        Layout.preferredWidth: 100
                        elide: Text.ElideRight
                    }

                    Label {
                        text: AppState.toUiPrice(salary)
                        color: "lightgreen"
                        Layout.preferredWidth: 80
                        elide: Text.ElideRight
                    }

                    Label {
                        text: addedDate
                        Layout.preferredWidth: 90
                    }

                    Label {
                        text: comment
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 0
                        ToolButton {
                            text: "Pay"
                            Layout.preferredHeight: 40
                            icon.source: "qrc:/icons/dollar.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Orange)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.employeeFilterModel, index)
                                AppState.employeeModel.payEmployee(sourceIndex.row)
                            }
                        }

                        ToolButton {
                            text: "Edit"
                            icon.source: "qrc:/icons/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Blue)
                            Layout.preferredHeight: 40
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.employeeFilterModel, index)
                                AppState.employeeDialog.editMode = true
                                AppState.employeeDialog.editIndex = sourceIndex.row
                                AppState.employeeDialog.loadEmployee(name, phone, role, salary, addedDate, comment)
                                AppState.employeeDialog.open()
                            }
                        }

                        ToolButton {
                            text: "Remove"
                            icon.source: "qrc:/icons/delete.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Red)
                            Layout.preferredHeight: 40
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.employeeFilterModel, index)
                                AppState.confirmDialog.title = "Remove Employee"
                                AppState.confirmDialog.confirmed.connect(function() {
                                    AppState.employeeModel.removeEntry(sourceIndex.row)
                                    AppState.confirmDialog.confirmed.disconnect(arguments.callee)
                                })
                                AppState.confirmDialog.open()
                            }
                        }
                    }
                }
            }
        }
    }
}
