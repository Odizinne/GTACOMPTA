import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: "Manage Supplements & Offers"
    width: 800
    height: 600
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    signal supplementAdded(string name, int price)
    signal supplementUpdated(int index, string name, int price)
    signal offerAdded(string name, int price)
    signal offerUpdated(int index, string name, int price)
    signal supplementRemoved(int index)
    signal offerRemoved(int index)

    RowLayout {
        id: headerRow
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        spacing: 0

        ToolButton {
            text: "New..."
            icon.source: "qrc:/icons/new.svg"
            icon.width: 16
            icon.height: 16
            icon.color: Material.color(Material.Lime)
            onClicked: {
                supplementOfferDialog.isOffer = managementTabBar.currentIndex === 1
                supplementOfferDialog.editMode = false
                supplementOfferDialog.open()
            }
        }

        TabBar {
            id: managementTabBar
            Layout.fillWidth: true

            TabButton {
                text: "Supplements (" + (AppState.supplementModel ? AppState.supplementModel.count : "0") + ")"
            }
            TabButton {
                text: "Offers (" + (AppState.offerModel ? AppState.offerModel.count : "0") + ")"
            }
        }
    }

    ToolBar {
        id: managmentHeader
        width: parent.width
        anchors.top: headerRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 4
        height: 35

        RowLayout {
            anchors.fill: parent
            anchors.margins: 5
            spacing: 10

            Label {
                Layout.leftMargin: 5
                text: "Name"
                Layout.fillWidth: true
            }

            Label {
                text: "Price"
                Layout.preferredWidth: 160
            }

            Label {
                text: "Actions"
                font.bold: true
                Layout.alignment: Qt.AlignRight
            }
        }
    }

    StackView {
        id: managementStackView
        anchors.top: managmentHeader.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        replaceEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        replaceExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        Component {
            id: supplementsTab
            ScrollView {
                width: managementStackView.width

                ListView {
                    id: supplListView
                    width: parent.width
                    model: AppState.supplementModel
                    spacing: 0

                    delegate: Rectangle {
                        width: supplListView.width
                        height: 40
                        color: (index % 2 === 0) ? "#404040" : "#303030"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10

                            Label {
                                text: model.name
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Label {
                                text: AppState.toUiPrice(model.price)
                                color: "lightgreen"
                                Layout.preferredWidth: 80
                            }

                            RowLayout {
                                spacing: 0
                                ToolButton {
                                    text: "Edit"
                                    icon.source: "qrc:/icons/edit.svg"
                                    icon.width: 16
                                    icon.height: 16
                                    icon.color: Material.color(Material.Blue)
                                    Layout.preferredHeight: 40
                                    onClicked: {
                                        supplementOfferDialog.isOffer = false
                                        supplementOfferDialog.editMode = true
                                        supplementOfferDialog.editIndex = index
                                        supplementOfferDialog.loadItem(model.name, model.price)
                                        supplementOfferDialog.open()
                                    }
                                }

                                ToolButton {
                                    text: "Remove"
                                    icon.source: "qrc:/icons/delete.svg"
                                    icon.width: 16
                                    icon.height: 16
                                    icon.color: Material.color(Material.Red)
                                    Layout.preferredHeight: 40
                                    onClicked: root.supplementRemoved(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: offersTab
            ScrollView {
                width: managementStackView.width

                ListView {
                    id: offerView
                    width: parent.width
                    model: AppState.offerModel
                    spacing: 0

                    delegate: Rectangle {
                        width: offerView.width
                        height: 40
                        color: (index % 2 === 0) ? "#404040" : "#303030"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10

                            Label {
                                text: model.name
                                font.bold: true
                                Layout.fillWidth: true
                            }

                            Label {
                                text: AppState.toUiPrice(model.price)
                                color: "lightgreen"
                                Layout.preferredWidth: 80
                            }
                            RowLayout {
                                spacing: 0
                                ToolButton {
                                    text: "Edit"
                                    icon.source: "qrc:/icons/edit.svg"
                                    icon.width: 16
                                    icon.height: 16
                                    icon.color: Material.color(Material.Blue)
                                    Layout.preferredHeight: 40
                                    onClicked: {
                                        supplementOfferDialog.isOffer = true
                                        supplementOfferDialog.editMode = true
                                        supplementOfferDialog.editIndex = index
                                        supplementOfferDialog.loadItem(model.name, model.price)
                                        supplementOfferDialog.open()
                                    }
                                }

                                ToolButton {
                                    text: "Remove"
                                    icon.source: "qrc:/icons/delete.svg"
                                    icon.width: 16
                                    icon.height: 16
                                    icon.color: Material.color(Material.Red)
                                    Layout.preferredHeight: 40
                                    onClicked: root.offerRemoved(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        initialItem: supplementsTab
    }

    Connections {
        target: managementTabBar
        function onCurrentIndexChanged() {
            var tabs = [supplementsTab, offersTab]
            if (managementTabBar.currentIndex < tabs.length) {
                managementStackView.replace(tabs[managementTabBar.currentIndex])
            }
        }
    }

    Dialog {
        id: supplementOfferDialog
        title: editMode ? ("Edit " + (isOffer ? "Offer" : "Supplement")) : ("Add New " + (isOffer ? "Offer" : "Supplement"))
        width: 400
        anchors.centerIn: parent
        modal: true
        Material.roundedScale: Material.ExtraSmallScale

        property bool editMode: false
        property int editIndex: -1
        property bool isOffer: false

        function loadItem(name, price) {
            itemName.text = name
            itemPrice.value = price
        }

        function clearFields() {
            itemName.clear()
            itemPrice.value = 100
        }

        onClosed: {
            editMode = false
            editIndex = -1
            clearFields()
        }

        GridLayout {
            anchors.fill: parent
            columns: 2
            rowSpacing: 10

            Label { text: "Type:" }
            ComboBox {
                Layout.preferredHeight: Constants.comboHeight
                id: typeCombo
                Layout.fillWidth: true
                model: ["Supplement", "Offer"]
                currentIndex: supplementOfferDialog.isOffer ? 1 : 0
                onCurrentIndexChanged: {
                    supplementOfferDialog.isOffer = currentIndex === 1
                }
            }

            Label { text: "Name:" }
            TextField {
                Layout.preferredHeight: Constants.comboHeight
                id: itemName
                Layout.fillWidth: true
                placeholderText: supplementOfferDialog.isOffer ? "Gold Package" : "Anti-Rust Coating"
            }

            Label { text: "Price ($):" }
            SpinBox {
                Layout.preferredHeight: Constants.comboHeight
                id: itemPrice
                Layout.fillWidth: true
                from: 0
                to: 999999
                value: 100
                editable: true
            }
        }

        footer: DialogButtonBox {
            Button {
                flat: true
                text: supplementOfferDialog.editMode ? "Update" : "Add"
                enabled: itemName.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    if (supplementOfferDialog.editMode) {
                        if (supplementOfferDialog.isOffer) {
                            root.offerUpdated(supplementOfferDialog.editIndex, itemName.text, itemPrice.value)
                        } else {
                            root.supplementUpdated(supplementOfferDialog.editIndex, itemName.text, itemPrice.value)
                        }
                    } else {
                        if (supplementOfferDialog.isOffer) {
                            root.offerAdded(itemName.text, itemPrice.value)
                        } else {
                            root.supplementAdded(itemName.text, itemPrice.value)
                        }
                    }
                    supplementOfferDialog.close()
                }
            }
            Button {
                flat: true
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: supplementOfferDialog.close()
            }
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Close"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.close()
        }
    }
}
