pragma ComponentBehavior: Bound

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
                color: Constants.secondaryTextColor
            }

            delegate: Rectangle {
                id: del
                width: employeeListView.width
                height: 40
                color: (index % 2 === 0) ? Constants.listItemEven : Constants.listItemOdd
                required property var model
                required property var index

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    spacing: 10

                    Label {
                        text: del.model.name
                        font.bold: true
                        Layout.preferredWidth: 120
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: del.model.phone
                        Layout.preferredWidth: 100
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: del.model.role
                        Layout.preferredWidth: 100
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: {
                            var salaryText = AppState.toUiPrice(del.model.salary)
                            if (salaryText.startsWith("+") || salaryText.startsWith("-")) {
                                salaryText = salaryText.substring(1)
                            }
                            return salaryText
                        }
                        color: Constants.debitColor
                        Layout.preferredWidth: 80
                        elide: Text.ElideRight
                    }

                    Label {
                        text: del.model.addedDate
                        Layout.preferredWidth: 90
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: del.model.comment
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
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
                                var sourceIndex = AppState.getSourceIndex(AppState.employeeFilterModel, del.index)
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
                                var sourceIndex = AppState.getSourceIndex(AppState.employeeFilterModel, del.index)
                                AppState.employeeDialog.editMode = true
                                AppState.employeeDialog.editIndex = sourceIndex.row
                                AppState.employeeDialog.loadEmployee(del.model.name, del.model.phone, del.model.role, del.model.salary, del.model.addedDate, del.model.comment)
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
                                var sourceIndex = AppState.getSourceIndex(AppState.employeeFilterModel, del.index)
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
