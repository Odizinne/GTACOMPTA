pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Column {
    id: root
    spacing: 0

    property int editingClientIndex: -1

    ToolBar {
        width: parent.width
        height: 35
        z: 1000

        RowLayout {
            anchors.fill: parent
            spacing: 20
            anchors.leftMargin: 10

            SortableLabel {
                headerText: "Type"
                sortColumn: ClientModel.SortByBusinessType
                sortModel: AppState.clientModel
                Layout.minimumWidth: 30
                Layout.preferredWidth: 30
                Layout.maximumWidth: 30
            }

            SortableLabel {
                headerText: "Name"
                sortColumn: ClientModel.SortByName
                sortModel: AppState.clientModel
                Layout.fillWidth: true
                Layout.minimumWidth: 50 // Prevent it from becoming too small
            }

            SortableLabel {
                headerText: "Offer"
                sortColumn: ClientModel.SortByOffer
                sortModel: AppState.clientModel
                Layout.minimumWidth: 100
                Layout.preferredWidth: 100
                Layout.maximumWidth: 100
            }

            SortableLabel {
                headerText: "Price"
                sortColumn: ClientModel.SortByPrice
                sortModel: AppState.clientModel
                Layout.minimumWidth: 60
                Layout.preferredWidth: 60
                Layout.maximumWidth: 60
            }

            Label {
                text: "Supplements"
                font.bold: true
                Layout.minimumWidth: 80
                Layout.preferredWidth: 80
                Layout.maximumWidth: 80
            }

            SortableLabel {
                headerText: "Disc"
                sortColumn: ClientModel.SortByDiscount
                sortModel: AppState.clientModel
                Layout.minimumWidth: 60
                Layout.preferredWidth: 60
                Layout.maximumWidth: 60
            }

            SortableLabel {
                headerText: "Phone"
                sortColumn: ClientModel.SortByPhone
                sortModel: AppState.clientModel
                Layout.minimumWidth: 100
                Layout.preferredWidth: 100
                Layout.maximumWidth: 100
            }

            SortableLabel {
                headerText: "Payment Date"
                sortColumn: ClientModel.SortByPaymentDate
                sortModel: AppState.clientModel
                Layout.minimumWidth: 90
                Layout.preferredWidth: 90
                Layout.maximumWidth: 90
            }

            Label {
                text: "Comment"
                font.bold: true
                Layout.minimumWidth: 80
                Layout.preferredWidth: 80
                Layout.maximumWidth: 80
            }

            Label {
                text: "Actions "
                font.bold: true
                Layout.minimumWidth: 240
                Layout.preferredWidth: 240
                Layout.maximumWidth: 240
                horizontalAlignment: Text.AlignRight
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    ClientCommentDialog {
        id: clientCommentDialog
        anchors.centerIn: parent
        signal notesUpdated(string text)
        enabled: !AppState.isReadOnly
        onClosed: {
            if (root.editingClientIndex >= 0) {
                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, root.editingClientIndex)
                AppState.clientModel.updateComment(sourceIndex.row, text)
                root.editingClientIndex = -1
            }
        }
    }

    ScrollView {
        width: parent.width
        height: parent.height - 35
        clip: true

        ListView {
            id: clientListView
            width: parent.width
            height: parent.parent.height
            model: AppState.clientFilterModel
            clip: true
            spacing: 0

            Label {
                anchors.centerIn: parent
                text: AppState.filterText ? "No clients match the filter." : "No clients added yet.\nUse Databases → New Client to add one."
                visible: clientListView.count === 0
                horizontalAlignment: Text.AlignHCenter
                color: Constants.secondaryTextColor
            }

            delegate: Rectangle {
                id: del
                width: clientListView.width
                height: 40
                color: (index % 2 === 0) ? Constants.listItemEven : Constants.listItemOdd
                required property var model
                required property var index
                property bool isHovered: false

                HoverHandler {
                    onHoveredChanged: del.isHovered = hovered
                }

                RowLayout {
                    anchors.fill: parent
                    spacing: 20
                    anchors.leftMargin: 10

                    Label {
                        text: del.model.businessType === 0 ? "Pro" : "Part"
                        font.bold: true
                        color: del.model.businessType === 0 ? Constants.businessColor : Constants.consumerColor
                        Layout.minimumWidth: 30
                        Layout.preferredWidth: 30
                        Layout.maximumWidth: 30
                    }

                    Label {
                        text: del.model.name
                        font.bold: true
                        Layout.fillWidth: true
                        Layout.minimumWidth: 50
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: {
                            if (del.model.offer >= 0 && del.model.offer < AppState.offerModel.count) {
                                return AppState.offerModel.getOfferName(del.model.offer)
                            }
                            return "Unknown"
                        }
                        Layout.minimumWidth: 100
                        Layout.preferredWidth: 100
                        Layout.maximumWidth: 100
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: {
                            var priceText = AppState.toUiPrice(del.model.price)
                            if (priceText.startsWith("+") || priceText.startsWith("-")) {
                                priceText = priceText.substring(1)
                            }
                            return priceText
                        }
                        Layout.minimumWidth: 60
                        Layout.preferredWidth: 60
                        Layout.maximumWidth: 60
                        elide: Text.ElideRight
                        color: Constants.creditColor
                    }

                    ToolButton {
                        Layout.preferredHeight: 40
                        text: {
                            var totalItems = 0
                            var suppMap = AppState.clientModel.getSupplementQuantities(del.index)
                            for (var key in suppMap) {
                                totalItems += suppMap[key]
                            }
                            return totalItems + " items"
                        }
                        Layout.minimumWidth: 80
                        Layout.preferredWidth: 80
                        Layout.maximumWidth: 80
                        onClicked: {
                            AppState.supplementDialog.currentSupplements = AppState.clientModel.getSupplementQuantities(del.index)
                            AppState.supplementDialog.readOnly = true
                            AppState.supplementDialog.open()
                        }
                    }

                    Label {
                        text: del.model.discount + "%"
                        Layout.minimumWidth: 60
                        Layout.preferredWidth: 60
                        Layout.maximumWidth: 60
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: del.model.phoneNumber
                        Layout.minimumWidth: 100
                        Layout.preferredWidth: 100
                        Layout.maximumWidth: 100
                        elide: Text.ElideRight
                        color: Constants.primaryTextColor
                    }

                    Label {
                        text: del.model.paymentDate
                        Layout.minimumWidth: 90
                        Layout.preferredWidth: 90
                        Layout.maximumWidth: 90
                        color: Constants.primaryTextColor
                    }

                    Item {
                        implicitWidth: 80
                        implicitHeight: 40
                        Layout.minimumWidth: 80
                        Layout.preferredWidth: 80
                        Layout.maximumWidth: 80
                        Layout.minimumHeight: 40
                        Layout.maximumHeight: 40
                        ToolButton {
                            implicitHeight: 40
                            anchors.fill: parent
                            text: "View"
                            onClicked: {
                                root.editingClientIndex = del.index
                                clientCommentDialog.text = del.model.comment
                                clientCommentDialog.open()
                            }
                        }
                    }

                    RowLayout {
                        spacing: 0
                        opacity: del.isHovered ? 1 : 0
                        Layout.minimumWidth: 240
                        Layout.preferredWidth: 240
                        Layout.maximumWidth: 240

                        Behavior on opacity {
                            NumberAnimation {
                                easing.type: Easing.Linear
                                duration: 100
                            }
                        }

                        ToolButton {
                            text: "Checkout"
                            enabled: !AppState.isReadOnly
                            icon.source: "qrc:/icons/dollar.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Orange)
                            Layout.preferredHeight: 40
                            Layout.fillWidth: true
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, del.index)
                                AppState.clientModel.checkout(sourceIndex.row)
                            }
                        }

                        ToolButton {
                            text: "Edit"
                            enabled: !AppState.isReadOnly
                            icon.source: "qrc:/icons/edit.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Blue)
                            Layout.preferredHeight: 40
                            Layout.fillWidth: true
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, del.index)
                                AppState.clientDialog.editMode = true
                                AppState.clientDialog.editIndex = sourceIndex.row
                                AppState.clientDialog.loadClient(del.model.businessType, del.model.name, del.model.offer, del.model.price,
                                                                 del.model.supplements, del.model.discount, del.model.phoneNumber, del.model.paymentDate, del.model.comment)
                                AppState.clientDialog.open()
                            }
                        }

                        ToolButton {
                            text: "Remove"
                            enabled: !AppState.isReadOnly
                            icon.source: "qrc:/icons/delete.svg"
                            icon.width: 16
                            icon.height: 16
                            icon.color: Material.color(Material.Red)
                            Layout.preferredHeight: 40
                            Layout.fillWidth: true
                            onClicked: {
                                var sourceIndex = AppState.getSourceIndex(AppState.clientFilterModel, del.index)
                                AppState.confirmDialog.showConfirmation("Remove Client", function() {
                                    AppState.clientModel.removeEntry(sourceIndex.row)
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}
