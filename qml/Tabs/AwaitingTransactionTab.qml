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
        z: 1000

        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 10

            SortableLabel {
                headerText: "Amount"
                sortColumn: AwaitingTransactionModel.SortByAmount
                sortModel: AppState.awaitingTransactionModel
                Layout.preferredWidth: 120
            }

            SortableLabel {
                headerText: "Date"
                sortColumn: AwaitingTransactionModel.SortByDate
                sortModel: AppState.awaitingTransactionModel
                Layout.preferredWidth: 100
            }

            SortableLabel {
                headerText: "Description"
                sortColumn: AwaitingTransactionModel.SortByDescription
                sortModel: AppState.awaitingTransactionModel
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
        clip: true

        ListView {
            id: awaitingTransactionListView
            width: parent.width
            height: parent.parent.height
            model: AppState.awaitingTransactionFilterModel
            clip: true
            spacing: 0

            Label {
                anchors.centerIn: parent
                text: AppState.filterText ? "No awaiting transactions match the filter." : "No awaiting transactions.\nTransactions will appear here when clients checkout or employees are paid."
                visible: awaitingTransactionListView.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: Constants.secondaryTextColor
            }

            delegate: Rectangle {
                id: del
                width: awaitingTransactionListView.width
                height: 40
                color: (index % 2 === 0) ? Constants.listItemEven : Constants.listItemOdd
                required property var model
                required property int index

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    spacing: 10

                    Label {
                        text: AppState.toUiPrice(del.model.amount)
                        color: del.model.amount >= 0 ? Constants.positiveAmountColor : Constants.negativeAmountColor
                        font.bold: true
                        Layout.preferredWidth: 120
                        elide: Text.ElideRight
                    }

                    Label {
                        text: del.model.date
                        color: Constants.secondaryTextColor
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: del.model.description
                        font.bold: true
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    RowLayout {
                        spacing: 0
                        ToolButton {
                            Layout.preferredHeight: 40
                            text: "Approve"
                            enabled: !AppState.isReadOnly
                            icon.source: "qrc:/icons/checkmark.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Green)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.awaitingTransactionFilterModel, del.index)
                                AppState.awaitingTransactionModel.approveTransaction(sourceIndex.row)
                            }
                        }

                        ToolButton {
                            Layout.preferredHeight: 40
                            text: "Edit"
                            enabled: !AppState.isReadOnly
                            icon.source: "qrc:/icons/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Blue)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.awaitingTransactionFilterModel, del.index)
                                AppState.awaitingTransactionDialog.editMode = true
                                AppState.awaitingTransactionDialog.editIndex = sourceIndex.row
                                AppState.awaitingTransactionDialog.loadTransaction(del.model.description, del.model.amount, del.model.date)
                                AppState.awaitingTransactionDialog.open()
                            }
                        }

                        ToolButton {
                            Layout.preferredHeight: 40
                            text: "Remove"
                            enabled: !AppState.isReadOnly
                            icon.source: "qrc:/icons/delete.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Red)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.awaitingTransactionFilterModel, del.index)
                                AppState.confirmDialog.showConfirmation("Remove Awaiting Transaction", function() {
                                    AppState.awaitingTransactionModel.removeEntry(sourceIndex.row)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}
