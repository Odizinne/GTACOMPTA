import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: editMode ? "Edit Employee" : "Add New Employee"
    width: 400
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property bool editMode: false
    property int editIndex: -1

    signal employeeAdded(string name, string phone, string role, int salary, string addedDate, string comment)
    signal employeeUpdated(int index, string name, string phone, string role, int salary, string addedDate, string comment)

    function loadEmployee(name, phone, role, salary, addedDate, comment) {
        empName.text = name
        empPhone.text = phone
        empRole.text = role
        empSalary.value = salary
        empAddedDate.selectedDate = new Date(addedDate)
        empComment.text = comment
    }

    function clearFields() {
        empName.clear()
        empPhone.clear()
        empRole.clear()
        empSalary.value = 500
        empAddedDate.selectedDate = new Date()
        empComment.clear()
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

        Label { text: "Name:" }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            id: empName
            Layout.fillWidth: true
            placeholderText: "John Doe"
        }

        Label { text: "Phone:" }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            id: empPhone
            Layout.fillWidth: true
            placeholderText: "+1234567890"
        }

        Label { text: "Role:" }
        TextField {
            Layout.preferredHeight: Constants.comboHeight
            id: empRole
            Layout.fillWidth: true
            placeholderText: "Developer"
        }

        Label { text: "Salary:" }
        SpinBox {
            Layout.preferredHeight: Constants.comboHeight
            id: empSalary
            Layout.fillWidth: true
            from: 0
            to: 999999
            stepSize: 1000
            value: 500
            editable: true
        }

        Label { text: "Added Date:" }
        DatePicker {
            id: empAddedDate
            Layout.fillWidth: true
            selectedDate: new Date()
            placeholderText: "Select employee start date"
            onOpenDateDialog: empDatePickerDialog.open()
        }

        Label { text: "Comment:" }
        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            TextArea {
                id: empComment
                placeholderText: "Additional comments..."
                wrapMode: TextArea.Wrap
            }
        }
    }

    DatePickerDialog {
        id: empDatePickerDialog
        selectedDate: empAddedDate.selectedDate
        onDateSelected: function(newDate) {
            empAddedDate.selectedDate = newDate
            empAddedDate.dateChanged(newDate)
        }
        onOpened: {
            currentDate = empAddedDate.selectedDate
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: root.editMode ? "Update" : "Add"
            enabled: empName.text.length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                if (root.editMode) {
                    root.employeeUpdated(root.editIndex, empName.text, empPhone.text, empRole.text,
                                        empSalary.value, empAddedDate.formatDate(empAddedDate.selectedDate),
                                        empComment.text)
                } else {
                    root.employeeAdded(empName.text, empPhone.text, empRole.text, empSalary.value,
                                      empAddedDate.formatDate(empAddedDate.selectedDate), empComment.text)
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
