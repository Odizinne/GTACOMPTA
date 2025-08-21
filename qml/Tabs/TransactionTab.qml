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
                headerText: "Amount"
                sortColumn: TransactionModel.SortByAmount
                sortModel: AppState.transactionModel
                Layout.preferredWidth: 120
            }

            SortableLabel {
                headerText: "Date"
                sortColumn: TransactionModel.SortByDate
                sortModel: AppState.transactionModel
                Layout.preferredWidth: 100
            }

            SortableLabel {
                headerText: "Description"
                sortColumn: TransactionModel.SortByDescription
                sortModel: AppState.transactionModel
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
                color: Constants.secondaryTextColor
            }

            delegate: Rectangle {
                id: del
                width: transactionListView.width
                height: 40
                color: (index % 2 === 0) ? Constants.listItemEven : Constants.listItemOdd
                required property var model
                required property var index

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
                            text: "Edit"
                            icon.source: "qrc:/icons/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Blue)
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.transactionFilterModel, del.index)
                                AppState.transactionDialog.editMode = true
                                AppState.transactionDialog.editIndex = sourceIndex.row
                                AppState.transactionDialog.loadTransaction(del.model.description, del.model.amount, del.model.date)
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
                                var sourceIndex = AppState.getSourceIndex(AppState.transactionFilterModel, del.index)
                                AppState.confirmDialog.title = "Remove Transaction"
                                AppState.confirmDialog.confirmed.connect(function() {
                                    AppState.companySummaryModel.subtractFromMoney(del.model.amount)
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
