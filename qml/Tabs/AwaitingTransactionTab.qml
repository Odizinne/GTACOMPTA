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
            id: awaitingTransactionListView
            width: parent.width
            height: parent.parent.height
            model: AppState.awaitingTransactionFilterModel
            spacing: 0

            Label {
                anchors.centerIn: parent
                text: AppState.filterText ? "No awaiting transactions match the filter." : "No awaiting transactions.\nTransactions will appear here when clients checkout or employees are paid."
                visible: awaitingTransactionListView.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: "gray"
            }

            delegate: Rectangle {
                width: awaitingTransactionListView.width
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
                            text: "Approve"
                            icon.source: "qrc:/icons/checkmark.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Green)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.awaitingTransactionFilterModel, index)
                                AppState.awaitingTransactionModel.approveTransaction(sourceIndex.row)
                            }
                        }

                        ToolButton {
                            Layout.preferredHeight: 40
                            text: "Edit"
                            icon.source: "qrc:/icons/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Blue)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.awaitingTransactionFilterModel, index)
                                AppState.awaitingTransactionDialog.editMode = true
                                AppState.awaitingTransactionDialog.editIndex = sourceIndex.row
                                AppState.awaitingTransactionDialog.loadTransaction(description, amount, date)
                                AppState.awaitingTransactionDialog.open()
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
                                var sourceIndex = AppState.getSourceIndex(AppState.awaitingTransactionFilterModel, index)
                                AppState.confirmDialog.title = "Remove Awaiting Transaction"
                                AppState.confirmDialog.confirmed.connect(function() {
                                    AppState.awaitingTransactionModel.removeEntry(sourceIndex.row)
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
