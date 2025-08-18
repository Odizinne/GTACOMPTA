import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    title: "Multi-Model Management"
    Material.theme: Material.Dark

    EmployeeModel {
        id: employeeModel
        Component.onCompleted: loadFromFile()
    }

    TransactionModel {
        id: transactionModel
        Component.onCompleted: loadFromFile()
    }

    ClientModel {
        id: clientModel
        Component.onCompleted: loadFromFile()
    }

    Connections {
        target: clientModel
        function onCheckoutCompleted(description, amount) {
            console.log("pass")
            transactionModel.addTransactionFromCheckout(description, amount)
            UserSettings.money += amount
        }
    }

    // Supplement List Model
    ListModel {
        id: supplementModel

        Component.onCompleted: {
            append({index: 1, name: "Extra Cheese", price: "2.50"})
            append({index: 2, name: "Bacon", price: "3.00"})
            append({index: 3, name: "Mushrooms", price: "1.75"})
            append({index: 4, name: "Pepperoni", price: "2.25"})
            append({index: 5, name: "Olives", price: "1.50"})
            append({index: 6, name: "Tomatoes", price: "1.25"})
        }
    }

    // Header with menu
    menuBar: MenuBar {
        Menu {
            title: "&File"

            MenuItem {
                text: "&New Employee..."
                onTriggered: employeeDialog.open()
            }
            MenuItem {
                text: "New &Transaction..."
                onTriggered: transactionDialog.open()
            }
            MenuItem {
                text: "New &Client..."
                onTriggered: clientDialog.open()
            }

            MenuSeparator { }

            MenuItem {
                text: "&Clear All Data"
                onTriggered: clearAllDialog.open()
            }

            MenuSeparator { }

            MenuItem {
                text: "E&xit"
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: "&View"

            MenuItem {
                text: "&Employees"
                checkable: true
                checked: tabBar.currentIndex === 0
                onTriggered: tabBar.currentIndex = 0
            }
            MenuItem {
                text: "&Transactions"
                checkable: true
                checked: tabBar.currentIndex === 1
                onTriggered: tabBar.currentIndex = 1
            }
            MenuItem {
                text: "&Clients"
                checkable: true
                checked: tabBar.currentIndex === 2
                onTriggered: tabBar.currentIndex = 2
            }
        }

        Menu {
            title: UserSettings.money
        }
    }

    TabBar {
        id: tabBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right

        TabButton {
            text: "Employees (" + employeeModel.count + ")"
        }
        TabButton {
            text: "Transactions (" + transactionModel.count + ")"
        }
        TabButton {
            text: "Clients (" + clientModel.count + ")"
        }
    }

    StackLayout {
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        //anchors.margins: 10
        currentIndex: tabBar.currentIndex

        // Employee Tab - Just the list
        Column {
            spacing: 0

            Rectangle {
                width: parent.width
                height: 40
                color: Material.primary

                Label {
                    anchors.centerIn: parent
                    text: "EMPLOYEES"
                    font.bold: true
                    font.pixelSize: 16
                    color: "white"
                }
            }

            ScrollView {
                width: parent.width
                height: parent.height - 40

                ListView {
                    anchors.fill: parent
                    model: employeeModel
                    spacing: 5

                    delegate: Rectangle {
                        width: parent.width
                        height: 80
                        border.color: "lightgray"
                        border.width: 1
                        radius: 5

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10

                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: name
                                    font.bold: true
                                    font.pixelSize: 16
                                }
                                Label {
                                    text: email + " | " + phone
                                    color: "gray"
                                    font.pixelSize: 12
                                }
                                Label {
                                    text: department + " - $" + salary.toLocaleString()
                                    color: "blue"
                                    font.pixelSize: 14
                                }
                            }

                            ToolButton {
                                text: "Edit"
                                onClicked: {
                                    employeeDialog.editMode = true
                                    employeeDialog.editIndex = index
                                    employeeDialog.loadEmployee(name, email, phone, department, salary)
                                    employeeDialog.open()
                                }
                            }

                            ToolButton {
                                text: "Remove"
                                onClicked: employeeModel.removeEntry(index)
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "No employees added yet.\nUse File → New Employee to add one."
                        visible: employeeModel.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        color: "gray"
                    }
                }
            }
        }

        // Transaction Tab - Just the list
        Column {
            spacing: 0

            Rectangle {
                width: parent.width
                height: 40
                color: Material.primary

                Label {
                    anchors.centerIn: parent
                    text: "TRANSACTIONS"
                    font.bold: true
                    font.pixelSize: 16
                    color: "white"
                }
            }

            ScrollView {
                width: parent.width
                height: parent.height - 40

                ListView {
                    anchors.fill: parent
                    model: transactionModel
                    spacing: 0

                    delegate: Rectangle {
                        width: parent.width
                        height: 70
                        color: (index % 2 === 0) ? "#404040" : "#303030"  // Mid grey for even, dark grey for odd
                        // Remove the border properties since you're using the same style as clients

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10

                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: description
                                    font.bold: true
                                    font.pixelSize: 16
                                }
                                Label {
                                    text: date
                                    color: "gray"
                                    font.pixelSize: 12
                                }
                            }

                            Label {
                                text: (amount >= 0 ? "+" : "") + "$" + Math.abs(amount).toLocaleString()
                                color: amount >= 0 ? "green" : "red"
                                font.bold: true
                                font.pixelSize: 16
                            }

                            ToolButton {
                                text: "Edit"
                                onClicked: {
                                    transactionDialog.editMode = true
                                    transactionDialog.editIndex = index
                                    transactionDialog.loadTransaction(description, amount, date)
                                    transactionDialog.open()
                                }
                            }

                            ToolButton {
                                text: "Remove"
                                onClicked: transactionModel.removeEntry(index)
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "No transactions added yet.\nUse File → New Transaction to add one."
                        visible: transactionModel.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        color: "gray"
                    }
                }
            }
        }

        // Client Tab - Just the list
        Column {
            spacing: 0

            Rectangle {
                width: parent.width
                height: 35
                color: Material.accent
                opacity: 0.3

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 10

                    Label {
                        text: "Type"
                        font.bold: true
                        Layout.preferredWidth: 20
                    }

                    Label {
                        text: "Name"
                        font.bold: true
                        Layout.preferredWidth: 120
                    }

                    Label  {
                        text: "Offer"
                        Layout.preferredWidth: 80
                    }

                    Label {
                        text: "Price"
                        font.bold: true
                        Layout.preferredWidth: 60
                    }

                    Label {
                        text: "Supplements"
                        font.bold: true
                        Layout.preferredWidth: 80
                    }

                    Label {
                        text: "Chest"
                        font.bold: true
                        Layout.preferredWidth: 40
                    }

                    Label {
                        text: "Disc"
                        font.bold: true
                        Layout.preferredWidth: 40
                    }

                    Label {
                        text: "Phone"
                        font.bold: true
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: "Comment"
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "Actions"
                        font.bold: true
                        Layout.preferredWidth: 100
                    }
                }
            }

            ScrollView {
                width: parent.width
                height: parent.height - 35

                Column {
                    width: parent.width

                    ListView {
                        id: clientListView
                        width: parent.width
                        height: parent.parent.height //- 35
                        model: clientModel
                        spacing: 0

                        delegate: Rectangle {
                            width: clientListView.width
                            height: 50
                            color: (index % 2 === 0) ? "#404040" : "#303030"  // Mid grey for even, dark grey for odd

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 10

                                Label {
                                    text: businessType === 0 ? "B" : "C"
                                    font.bold: true
                                    color: businessType === 0 ? "blue" : "green"
                                    Layout.preferredWidth: 20
                                }

                                Label {
                                    text: name
                                    font.bold: true
                                    Layout.preferredWidth: 120
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: {
                                        switch(offer) {
                                            case 0: return "Bronze"
                                            case 1: return "Silver"
                                            case 2: return "Gold"
                                            default: return "Bronze"
                                        }
                                    }
                                    Layout.preferredWidth: 80
                                }

                                Label {
                                    text: "$" + price
                                    Layout.preferredWidth: 60
                                }

                                ToolButton {
                                    text: supplements.length + " supp"
                                    Layout.preferredWidth: 80
                                    onClicked: {
                                        supplementDialog.currentSupplements = supplements
                                        supplementDialog.readOnly = true
                                        supplementDialog.open()
                                    }
                                }

                                Label {
                                    text: "C" + chestID
                                    Layout.preferredWidth: 40
                                }

                                Label {
                                    text: discount + "%"
                                    Layout.preferredWidth: 40
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

                                ToolButton {
                                    text: "Checkout"
                                    Layout.preferredWidth: 70
                                    onClicked: clientModel.checkout(index)
                                }

                                ToolButton {
                                    text: "Edit"
                                    Layout.preferredWidth: 40
                                    onClicked: {
                                        clientDialog.editMode = true
                                        clientDialog.editIndex = index
                                        clientDialog.loadClient(businessType, name, offer, price,
                                                                supplements, chestID, discount, phoneNumber, comment)
                                        clientDialog.open()
                                    }
                                }

                                ToolButton {
                                    text: "Remove"
                                    Layout.preferredWidth: 60
                                    onClicked: clientModel.removeEntry(index)
                                }
                            }
                        }
                    }

                    Label {
                        anchors.centerIn: parent
                        text: "No clients added yet.\nUse File → New Client to add one."
                        visible: clientModel.count === 0
                        horizontalAlignment: Text.AlignHCenter
                        color: "gray"
                    }
                }
            }
        }
    }

    // Supplement Selection Dialog
    Dialog {
        id: supplementDialog
        title: readOnly ? "View Supplements" : "Select Supplements"
        width: 400
        height: 500
        anchors.centerIn: parent
        modal: true

        property var currentSupplements: []
        property bool readOnly: false

        function getSelectedSupplements() {
            var selected = []
            for (var i = 0; i < supplementRepeater.count; i++) {
                var checkbox = supplementRepeater.itemAt(i)
                if (checkbox.checked) {
                    selected.push(supplementModel.get(i).index)
                }
            }
            return selected
        }

        function setSelectedSupplements(supplements) {
            for (var i = 0; i < supplementRepeater.count; i++) {
                var checkbox = supplementRepeater.itemAt(i)
                var supplementIndex = supplementModel.get(i).index
                checkbox.checked = supplements.includes(supplementIndex)
            }
        }

        onOpened: {
            setSelectedSupplements(currentSupplements)
        }

        ScrollView {
            anchors.fill: parent

            Column {
                width: parent.width
                spacing: 5

                Repeater {
                    id: supplementRepeater
                    model: supplementModel

                    CheckBox {
                        width: parent.width
                        enabled: !supplementDialog.readOnly
                        text: model.name + " - $" + model.price

                        background: Rectangle {
                            color: parent.checked ? Material.accent : "transparent"
                            opacity: 0.2
                            radius: 4
                        }
                    }
                }
            }
        }

        footer: DialogButtonBox {
            Button {
                text: "OK"
                visible: supplementDialog.readOnly
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: supplementDialog.close()
            }

            Button {
                text: "Apply"
                visible: !supplementDialog.readOnly
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    clientDialog.selectedSupplements = supplementDialog.getSelectedSupplements()
                    supplementDialog.close()
                }
            }

            Button {
                text: "Cancel"
                visible: !supplementDialog.readOnly
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: supplementDialog.close()
            }
        }
    }

    // Employee Dialog
    Dialog {
        id: employeeDialog
        title: editMode ? "Edit Employee" : "Add New Employee"
        width: 400
        height: 350
        anchors.centerIn: parent
        modal: true

        property bool editMode: false
        property int editIndex: -1

        function loadEmployee(name, email, phone, department, salary) {
            empName.text = name
            empEmail.text = email
            empPhone.text = phone
            empDepartment.text = department
            empSalary.value = salary
        }

        function clearFields() {
            empName.clear()
            empEmail.clear()
            empPhone.clear()
            empDepartment.clear()
            empSalary.value = 50000
        }

        onClosed: {
            editMode = false
            editIndex = -1
            clearFields()
        }

        GridLayout {
            anchors.fill: parent
            columns: 2

            Label { text: "Name:" }
            TextField {
                id: empName
                Layout.fillWidth: true
                placeholderText: "John Doe"
            }

            Label { text: "Email:" }
            TextField {
                id: empEmail
                Layout.fillWidth: true
                placeholderText: "john@company.com"
            }

            Label { text: "Phone:" }
            TextField {
                id: empPhone
                Layout.fillWidth: true
                placeholderText: "+1234567890"
            }

            Label { text: "Department:" }
            TextField {
                id: empDepartment
                Layout.fillWidth: true
                placeholderText: "Engineering"
            }

            Label { text: "Salary:" }
            SpinBox {
                id: empSalary
                Layout.fillWidth: true
                from: 0
                to: 999999
                stepSize: 1000
                value: 50000

                textFromValue: function(value, locale) {
                    return "$" + value.toLocaleString(locale, 'f', 0)
                }
            }
        }

        footer: DialogButtonBox {
            Button {
                text: employeeDialog.editMode ? "Update" : "Add"
                enabled: empName.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    if (employeeDialog.editMode) {
                        employeeModel.updateEmployee(employeeDialog.editIndex, empName.text,
                                                     empEmail.text, empPhone.text, empDepartment.text, empSalary.value)
                    } else {
                        employeeModel.addEmployee(empName.text, empEmail.text,
                                                  empPhone.text, empDepartment.text, empSalary.value)
                    }
                    employeeDialog.close()
                }
            }
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: employeeDialog.close()
            }
        }
    }

    // Transaction Dialog
    Dialog {
        id: transactionDialog
        title: editMode ? "Edit Transaction" : "Add New Transaction"
        width: 400
        height: 250
        anchors.centerIn: parent
        modal: true

        property bool editMode: false
        property int editIndex: -1

        function loadTransaction(description, amount, date) {
            transDesc.text = description
            transAmount.value = amount
            transDate.text = date
        }

        function clearFields() {
            transDesc.clear()
            transAmount.value = 100
            transDate.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd")
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

                textFromValue: function(value, locale) {
                    return "$" + value.toLocaleString(locale, 'f', 0)
                }
            }

            Label { text: "Date:" }
            TextField {
                id: transDate
                Layout.fillWidth: true
                placeholderText: "YYYY-MM-DD"
                text: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
            }
        }

        footer: DialogButtonBox {
            Button {
                text: transactionDialog.editMode ? "Update" : "Add"
                enabled: transDesc.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    if (transactionDialog.editMode) {
                        transactionModel.updateTransaction(transactionDialog.editIndex, transDesc.text,
                                                           transAmount.value, transDate.text)
                    } else {
                        transactionModel.addTransaction(transDesc.text, transAmount.value, transDate.text)
                    }
                    transactionDialog.close()
                }
            }
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: transactionDialog.close()
            }
        }
    }

    // Client Dialog
    Dialog {
        id: clientDialog
        title: editMode ? "Edit Client" : "Add New Client"
        width: 500
        //height: 450
        anchors.centerIn: parent
        modal: true

        property bool editMode: false
        property int editIndex: -1
        property var selectedSupplements: []

        function loadClient(businessType, name, offer, price, supplements, chestID, discount, phoneNumber, comment) {
            businessTypeCombo.currentIndex = businessType
            clientName.text = name
            clientOfferCombo.currentIndex = offer
            clientDialog.selectedSupplements = supplements
            clientChestID.value = chestID
            clientDiscount.value = discount
            clientPhone.text = phoneNumber
            clientComment.text = comment
        }

        function clearFields() {
            businessTypeCombo.currentIndex = 0
            clientName.clear()
            clientOfferCombo.currentIndex = 0
            clientDialog.selectedSupplements = []
            clientChestID.value = 1
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
            anchors.fill: parent
            columns: 2

            Label { text: "Type:" }
            ComboBox {
                id: businessTypeCombo
                Layout.fillWidth: true
                model: ["Business", "Consumer"]
            }

            Label { text: "Name:" }
            TextField {
                id: clientName
                Layout.fillWidth: true
                placeholderText: "Client name"
            }

            Label { text: "Offer:" }
            ComboBox {
                id: clientOfferCombo
                Layout.fillWidth: true
                model: ["Bronze", "Silver", "Gold"]
            }

            Label { text: "Price:" }
            Label {
                id: calculatedPrice
                Layout.fillWidth: true
                text: "$" + (clientModel.calculatePrice(
                    clientOfferCombo.currentIndex,
                    clientDialog.selectedSupplements,
                    clientDiscount.value
                )).toFixed(2)

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: Material.accent
                    border.width: 1
                    radius: 4
                }
            }

            Label { text: "Supplements:" }
            RowLayout {
                Layout.fillWidth: true

                Label {
                    text: clientDialog.selectedSupplements.length + " selected"
                    Layout.fillWidth: true
                }

                Button {
                    text: "Select..."
                    onClicked: {
                        supplementDialog.currentSupplements = clientDialog.selectedSupplements
                        supplementDialog.readOnly = false
                        supplementDialog.open()
                    }
                }
            }

            Label { text: "Chest ID:" }
            SpinBox {
                id: clientChestID
                Layout.fillWidth: true
                from: 1
                to: 999
                value: 1
            }

            Label { text: "Discount (%):" }
            SpinBox {
                id: clientDiscount
                Layout.fillWidth: true
                from: 0
                to: 100
                value: 0
            }

            Label { text: "Phone:" }
            TextField {
                id: clientPhone
                Layout.fillWidth: true
                placeholderText: "+1234567890"
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

        footer: DialogButtonBox {
            Button {
                text: clientDialog.editMode ? "Update" : "Add"
                enabled: clientName.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    var calculatedPriceValue = clientModel.calculatePrice(
                        clientOfferCombo.currentIndex,
                        clientDialog.selectedSupplements,
                        clientDiscount.value
                    )

                    if (clientDialog.editMode) {
                        clientModel.updateClient(clientDialog.editIndex, businessTypeCombo.currentIndex,
                                                 clientName.text, clientOfferCombo.currentIndex, calculatedPriceValue,
                                                 clientDialog.selectedSupplements,
                                                 clientChestID.value, clientDiscount.value,
                                                 clientPhone.text, clientComment.text)
                    } else {
                        clientModel.addClient(businessTypeCombo.currentIndex, clientName.text,
                                              clientOfferCombo.currentIndex, calculatedPriceValue,
                                              clientDialog.selectedSupplements,
                                              clientChestID.value, clientDiscount.value,
                                              clientPhone.text, clientComment.text)
                    }
                    clientDialog.close()
                }
            }
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: clientDialog.close()
            }
        }
    }

    // Clear All Confirmation Dialog
    Dialog {
        id: clearAllDialog
        title: "Clear All Data"
        width: 300
        anchors.centerIn: parent
        modal: true

        Label {
            anchors.fill: parent
            text: "Are you sure you want to clear all data?\nThis action cannot be undone."
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        footer: DialogButtonBox {
            Button {
                text: "Clear All"
                DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
                onClicked: {
                    employeeModel.clear()
                    transactionModel.clear()
                    clientModel.clear()
                    clearAllDialog.close()
                }
            }
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: clearAllDialog.close()
            }
        }
    }
}
