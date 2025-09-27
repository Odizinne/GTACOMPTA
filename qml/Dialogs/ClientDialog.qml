import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: editMode ? "Edit Client" : "Add New Client"
    width: 500
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property bool editMode: false
    property int editIndex: -1
    property var selectedSupplements: []
    property var supplementQuantities: ({})

    signal clientAdded(int businessType, string name, int offer, real price, var supplementQuantities, int discount, string phoneNumber, string comment)
    signal clientUpdated(int index, int businessType, string name, int offer, real price, var supplementQuantities, int discount, string phoneNumber, string comment)
    signal supplementManagementRequested()

    function calculatePrice() {
        var basePrice = 0
        if (clientOfferCombo.currentIndex >= 0 && clientOfferCombo.currentIndex < AppState.offerModel.count) {
            basePrice = AppState.offerModel.getOfferPrice(clientOfferCombo.currentIndex)
        }

        var supplementsTotal = 0
        for (var suppIdStr in supplementQuantities) {
            var suppId = parseInt(suppIdStr)
            var quantity = supplementQuantities[suppIdStr]
            if (suppId >= 0 && suppId < AppState.supplementModel.count && quantity > 0) {
                supplementsTotal += AppState.supplementModel.getSupplementPrice(suppId) * quantity
            }
        }

        var totalBeforeDiscount = basePrice + supplementsTotal
        var finalPrice = totalBeforeDiscount * (100 - clientDiscount.value) / 100

        return finalPrice
    }

    function loadClient(businessType, name, offer, price, supplements, discount, phoneNumber, comment) {
        businessTypeCombo.currentIndex = businessType
        clientName.text = name
        clientOfferCombo.currentIndex = offer
        root.selectedSupplements = supplements

        if (editMode && editIndex >= 0) {
            root.supplementQuantities = AppState.clientModel.getSupplementQuantities(editIndex)
        } else {
            var quantities = {}
            if (supplements) {
                var supplementsArray = Array.isArray(supplements) ? supplements : []
                for (var i = 0; i < supplementsArray.length; i++) {
                    quantities[supplementsArray[i].toString()] = 1
                }
            }
            root.supplementQuantities = quantities
        }

        clientDiscount.value = discount
        clientPhone.text = phoneNumber
        clientComment.text = comment
    }

    function clearFields() {
        businessTypeCombo.currentIndex = 0
        clientName.clear()
        clientOfferCombo.currentIndex = 0
        root.selectedSupplements = []
        root.supplementQuantities = {}
        clientDiscount.value = 0
        clientPhone.clear()
        clientComment.clear()
    }

    onClosed: {
        editMode = false
        editIndex = -1
        clearFields()
    }

    GridLayout {
        enabled: !AppState.isReadOnly
        anchors.fill: parent
        columns: 2
        rowSpacing: 10

        Label { text: "Type:" }
        ComboBox {
            Layout.preferredHeight: Constants.comboHeight
            id: businessTypeCombo
            Layout.fillWidth: true
            model: ["Pro", "Part"]
        }

        Label { text: "Name:" }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            id: clientName
            Layout.fillWidth: true
            placeholderText: "Client name"
        }

        Label { text: "Phone:" }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            id: clientPhone
            Layout.fillWidth: true
            placeholderText: "+1234567890"
        }

        Label { text: "Offer:" }
        RowLayout {
            Layout.fillWidth: true

            ComboBox {
                Layout.preferredHeight: Constants.comboHeight
                id: clientOfferCombo
                Layout.fillWidth: true
                model: AppState.offerModel
                textRole: "name"
                onCurrentIndexChanged: calculatedPrice.updatePrice()
            }

            Button {
                id: manageOffersButton
                text: "Manage..."
                onClicked: root.supplementManagementRequested()
            }
        }

        Label { text: "Supplements:" }
        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Select..."
                Layout.preferredWidth: manageOffersButton.width
                onClicked: {
                    supplementDialog.currentSupplements = root.supplementQuantities
                    supplementDialog.readOnly = false
                    supplementDialog.open()
                }
            }
        }

        Label { text: "Discount (%):" }
        RowLayout {
            Layout.fillWidth: true

            Item {
                Layout.fillWidth: true
            }
            SpinBox {
                Layout.preferredHeight: Constants.comboHeight
                id: clientDiscount
                from: -100
                to: 100
                value: 0
                editable: true
                onValueChanged: calculatedPrice.updatePrice()
            }
        }

        Label { text: "Final Price:" }
        RowLayout {
            Item {
                Layout.fillWidth: true
            }

            Label {
                id: calculatedPrice
                Layout.preferredHeight: Constants.comboHeight
                Layout.preferredWidth: implicitWidth + 20
                text: {
                    var priceText = AppState.toUiPrice(root.calculatePrice())
                    if (priceText.startsWith("+") || priceText.startsWith("-")) {
                        priceText = priceText.substring(1)
                    }
                    return priceText
                }
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                function updatePrice() {
                    var priceText = AppState.toUiPrice(root.calculatePrice())
                    if (priceText.startsWith("+") || priceText.startsWith("-")) {
                        priceText = priceText.substring(1)
                    }
                    text = priceText
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Material.accent
                    border.width: 1
                    radius: 4
                }
            }
        }

        Label { text: "Comment:" }
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            TextArea {
                id: clientComment
                placeholderText: "Additional comments..."
                wrapMode: TextArea.Wrap
            }
        }
    }

    Connections {
        target: root
        function onSupplementQuantitiesChanged() {
            calculatedPrice.updatePrice()
        }
    }

    SupplementSelectionDialog {
        id: supplementDialog
        onSupplementsSelected: function(quantities) {
            root.supplementQuantities = quantities
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: root.editMode ? "Update" : "Add"
            enabled: clientName.text.length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                var calculatedPriceValue = root.calculatePrice()

                if (root.editMode) {
                    root.clientUpdated(root.editIndex, businessTypeCombo.currentIndex, clientName.text,
                                      clientOfferCombo.currentIndex, calculatedPriceValue,
                                      root.supplementQuantities, clientDiscount.value,
                                      clientPhone.text, clientComment.text)
                } else {
                    root.clientAdded(businessTypeCombo.currentIndex, clientName.text,
                                    clientOfferCombo.currentIndex, calculatedPriceValue,
                                    root.supplementQuantities, clientDiscount.value,
                                    clientPhone.text, clientComment.text)
                }
                root.close()
            }
        }
        Button {
            flat: true
            text: "Cancel"
            DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            onClicked: root.close()
        }
    }
}
