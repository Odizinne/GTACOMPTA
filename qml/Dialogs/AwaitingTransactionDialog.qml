import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts

Dialog {
    id: root
    title: editMode ? "Edit Awaiting Transaction" : "Add New Awaiting Transaction"
    width: 400
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property bool editMode: false
    property int editIndex: -1

    signal awaitingTransactionAdded(string description, real amount, string date)
    signal awaitingTransactionUpdated(int index, string description, real amount, string date)

    function loadTransaction(description, amount, date) {
        awaitingTransDesc.text = description
        awaitingTransAmount.value = amount
        awaitingTransDate.text = date
    }

    function clearFields() {
        awaitingTransDesc.clear()
        awaitingTransAmount.value = 100
        awaitingTransDate.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd")
    }

    onClosed: {
        editMode = false
        editIndex = -1
        clearFields()
    }

    GridLayout {
        anchors.fill: parent
        columns: 2

        Label { text: "Description:" }
        TextField {
            id: awaitingTransDesc
            Layout.fillWidth: true
            placeholderText: "Office supplies"
        }

        Label { text: "Amount:" }
        SpinBox {
            id: awaitingTransAmount
            Layout.fillWidth: true
            from: -999999
            to: 999999
            value: 100
            editable: true
        }

        Label { text: "Date:" }
        TextField {
            id: awaitingTransDate
            Layout.fillWidth: true
            placeholderText: "YYYY-MM-DD"
            text: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: root.editMode ? "Update" : "Add"
            enabled: awaitingTransDesc.text.length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                if (root.editMode) {
                    root.awaitingTransactionUpdated(root.editIndex, awaitingTransDesc.text,
                                                   awaitingTransAmount.value, awaitingTransDate.text)
                } else {
                    root.awaitingTransactionAdded(awaitingTransDesc.text, awaitingTransAmount.value,
                                                 awaitingTransDate.text)
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
