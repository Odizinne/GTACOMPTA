import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: editMode ? "Edit Transaction" : "Add New Transaction"
    width: 400
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property bool editMode: false
    property int editIndex: -1

    signal transactionAdded(string description, real amount, string date, bool skip)
    signal transactionUpdated(int index, string description, real amount, string date)

    function loadTransaction(description, amount, date) {
        transDesc.text = description
        transAmount.value = amount
        transDate.selectedDate = new Date(date)
    }

    function clearFields() {
        transDesc.clear()
        transAmount.value = 100
        transDate.selectedDate = new Date()
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
            id: transDesc
            Layout.fillWidth: true
            placeholderText: "Office supplies"
        }

        Label { text: "Amount:" }
        SpinBox {
            id: transAmount
            Layout.fillWidth: true
            from: -999999
            to: 999999
            value: 100
            editable: true
        }

        Label { text: "Date:" }
        DatePicker {
            id: transDate
            Layout.fillWidth: true
            selectedDate: new Date()
            placeholderText: "Select transaction date"
            onOpenDateDialog: transDatePickerDialog.open()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.columnSpan: 2
            Label {
                text: "Skip approval"
                Layout.fillWidth: true
            }

            CheckBox {
                id: skipApprovalCheckbox
                visible: !root.editMode
            }
        }
    }

    DatePickerDialog {
        id: transDatePickerDialog
        selectedDate: transDate.selectedDate
        onDateSelected: function(newDate) {
            transDate.selectedDate = newDate
            transDate.dateChanged(newDate)
        }
        onOpened: {
            currentDate = transDate.selectedDate
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: root.editMode ? "Update" : "Add"
            enabled: transDesc.text.length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                var dateString = transDate.formatDate(transDate.selectedDate)
                if (root.editMode) {
                    root.transactionUpdated(root.editIndex, transDesc.text, transAmount.value, dateString)
                } else {
                    root.transactionAdded(transDesc.text, transAmount.value, dateString, skipApprovalCheckbox.checked)
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
