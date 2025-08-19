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

            Label {
                text: "Amount"
                font.bold: true
                Layout.preferredWidth: 120
            }

            Label {
                text: "Date"
                font.bold: true
                Layout.preferredWidth: 100
            }

            Label {
                text: "Description"
                font.bold: true
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
            id: transactionListView
            width: parent.width
            height: parent.parent.height
            model: AppState.transactionFilterModel
            spacing: 0

            Label {
                anchors.centerIn: parent
                text: AppState.filterText ? "No transactions match the filter." : "No transactions added yet.\nUse Databases → New Transaction to add one."
                visible: transactionListView.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: "gray"
            }

            delegate: Rectangle {
                width: transactionListView.width
                height: 40
                color: (index % 2 === 0) ? "#404040" : "#303030"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    spacing: 10

                    Label {
                        text: (amount >= 0 ? "+" : "") + AppState.toUiPrice(amount)
                        color: amount >= 0 ? "lightgreen" : "lightcoral"
                        font.bold: true
                        Layout.preferredWidth: 120
                        elide: Text.ElideRight
                    }

                    Label {
                        text: date
                        color: "gray"
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: description
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 0
                        ToolButton {
                            Layout.preferredHeight: 40
                            text: "Edit"
                            icon.source: "qrc:/icons/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Blue)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.transactionFilterModel, index)
                                AppState.transactionDialog.editMode = true
                                AppState.transactionDialog.editIndex = sourceIndex.row
                                AppState.transactionDialog.loadTransaction(description, amount, date)
                                AppState.transactionDialog.open()
                            }
                        }

                        ToolButton {
                            Layout.preferredHeight: 40
                            text: "Remove"
                            icon.source: "qrc:/icons/delete.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Red)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.transactionFilterModel, index)
                                AppState.confirmDialog.title = "Remove Transaction"
                                AppState.confirmDialog.confirmed.connect(function() {
                                    UserSettings.money -= amount
                                    AppState.transactionModel.removeEntry(sourceIndex.row)
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
