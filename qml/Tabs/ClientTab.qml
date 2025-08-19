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
                headerText: "Type"
                sortColumn: ClientModel.SortByBusinessType
                sortModel: AppState.clientModel
                Layout.preferredWidth: 30
            }

            SortableLabel {
                headerText: "Name"
                sortColumn: ClientModel.SortByName
                sortModel: AppState.clientModel
                Layout.preferredWidth: 120
            }

            SortableLabel {
                headerText: "Offer"
                sortColumn: ClientModel.SortByOffer
                sortModel: AppState.clientModel
                Layout.preferredWidth: 80
            }

            SortableLabel {
                headerText: "Price"
                sortColumn: ClientModel.SortByPrice
                sortModel: AppState.clientModel
                Layout.preferredWidth: 60
            }

            Label {
                text: "Supplements"
                font.bold: true
                Layout.preferredWidth: 80
            }

            SortableLabel {
                headerText: "Disc"
                sortColumn: ClientModel.SortByDiscount
                sortModel: AppState.clientModel
                Layout.preferredWidth: 40
            }

            SortableLabel {
                headerText: "Phone"
                sortColumn: ClientModel.SortByPhone
                sortModel: AppState.clientModel
                Layout.preferredWidth: 100
            }

            SortableLabel {
                headerText: "Comment"
                sortColumn: ClientModel.SortByComment
                sortModel: AppState.clientModel
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
            id: clientListView
            width: parent.width
            height: parent.parent.height
            model: AppState.clientFilterModel
            spacing: 0

            Label {
                anchors.centerIn: parent
                text: AppState.filterText ? "No clients match the filter." : "No clients added yet.\nUse Databases → New Client to add one."
                visible: clientListView.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: "gray"
            }

            delegate: Rectangle {
                width: clientListView.width
                height: 40
                color: (index % 2 === 0) ? "#404040" : "#303030"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    spacing: 10

                    Label {
                        text: businessType === 0 ? "Pro" : "Part"
                        font.bold: true
                        color: businessType === 0 ? Constants.businessColor : Constants.consumerColor
                        Layout.preferredWidth: 30
                    }

                    Label {
                        text: name
                        font.bold: true
                        Layout.preferredWidth: 120
                        elide: Text.ElideRight
                    }

                    Label {
                        text: {
                            if (offer >= 0 && offer < AppState.offerModel.count) {
                                return AppState.offerModel.getOfferName(offer)
                            }
                            return "Unknown"
                        }
                        Layout.preferredWidth: 80
                        elide: Text.ElideRight
                    }

                    Label {
                        text: AppState.toUiPrice(price)
                        Layout.preferredWidth: 60
                        elide: Text.ElideRight
                    }

                    ToolButton {
                        Layout.preferredHeight: 40
                        text: {
                            var totalItems = 0
                            var suppMap = AppState.clientModel.getSupplementQuantities(index)
                            for (var key in suppMap) {
                                totalItems += suppMap[key]
                            }
                            return totalItems + " items"
                        }
                        Layout.preferredWidth: 80
                        onClicked: {
                            AppState.supplementDialog.currentSupplements = AppState.clientModel.getSupplementQuantities(index)
                            AppState.supplementDialog.readOnly = true
                            AppState.supplementDialog.open()
                        }
                    }

                    Label {
                        text: discount + "%"
                        Layout.preferredWidth: 40
                        elide: Text.ElideRight
                    }

                    Label {
                        text: phoneNumber
                        Layout.preferredWidth: 100
                        elide: Text.ElideRight
                    }

                    Label {
                        text: comment
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 0
                        ToolButton {
                            text: "Checkout"
                            icon.source: "qrc:/icons/dollar.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Orange)
                            Layout.preferredHeight: 40
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, index)
                                AppState.clientModel.checkout(sourceIndex.row)
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
                                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, index)
                                AppState.clientDialog.editMode = true
                                AppState.clientDialog.editIndex = sourceIndex.row
                                AppState.clientDialog.loadClient(businessType, name, offer, price,
                                                              supplements, discount, phoneNumber, comment)
                                AppState.clientDialog.open()
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
                                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, index)
                                AppState.confirmDialog.title = "Remove Client"
                                AppState.confirmDialog.confirmed.connect(function() {
                                    AppState.clientModel.removeEntry(sourceIndex.row)
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
