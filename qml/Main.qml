import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQml
import Odizinne.GTACOMPTA

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 720
    title: "GTACOMPTA"
    Material.theme: Material.Dark

    Component.onCompleted: {
        if (UserSettings.firstRun) {
            welcomeDialog.open()
        }
    }

    Material.primary: "#2A2F2A"
    Material.background: "#232323"
    Material.accent: "#4CAF50"
    color: "#1A1A1A"

    EmployeeModel {
        id: employeeModel
        Component.onCompleted: loadFromFile()
    }

    TransactionModel {
        id: transactionModel
        Component.onCompleted: loadFromFile()
    }

    AwaitingTransactionModel {
        id: awaitingTransactionModel
        Component.onCompleted: loadFromFile()
    }

    ClientModel {
        id: clientModel
        Component.onCompleted: loadFromFile()
    }

    FakeUpgradeDialog {
        id: fakeUpgradeDialog
    }

    WelcomeDialog {
        id: welcomeDialog
    }

    VersionDialog {
        id: versionDialog
    }

    Connections {
        target: clientModel
        function onCheckoutCompleted(description, amount) {
            console.log("Adding to awaiting transactions")
            awaitingTransactionModel.addAwaitingTransaction(description, amount, Qt.formatDateTime(new Date(), "yyyy-MM-dd"))
        }
    }

    Connections {
        target: employeeModel
        function onPaymentCompleted(description, amount) {
            awaitingTransactionModel.addAwaitingTransaction(description, amount, Qt.formatDateTime(new Date(), "yyyy-MM-dd"))
        }
    }

    Connections {
        target: awaitingTransactionModel
        function onTransactionApproved(description, amount, date) {
            transactionModel.addTransaction(description, amount, date)
        }
    }

    Connections {
        target: transactionModel
        function onRowsInserted(parent, first, last) {
            // When transactions are added, update money
            for (var i = first; i <= last; i++) {
                var amount = transactionModel.getTransactionAmount(i)
                UserSettings.money += amount
            }
        }
    }

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
    header: ToolBar {
        height: 41
        Material.primary: Material.dialogColor
        Item {
            anchors.fill: parent
            MenuBar {
                anchors.left: parent.left
                //Layout.fillWidth: true
                //Layout.fillHeight: true
                height: 41
                Menu {
                    title: "File"

                    MenuItem {
                        text: "New Employee..."
                        onTriggered: employeeDialog.open()
                    }
                    MenuItem {
                        text: "New Transaction..."
                        onTriggered: transactionDialog.open()
                    }
                    MenuItem {
                        text: "New Client..."
                        onTriggered: clientDialog.open()
                    }

                    MenuSeparator { }

                    MenuItem {
                        text: "Clear All Data"
                        onTriggered: clearAllDialog.open()
                    }

                    MenuSeparator { }

                    MenuItem {
                        text: "Exit"
                        onTriggered: Qt.quit()
                    }
                }

                Menu {
                    title: "Additions"

                    MenuItem {
                        text: "Connect to FiveM"
                        onTriggered: fakeUpgradeDialog.open()
                    }
                }
            }

            RowLayout {
                anchors.centerIn: parent

                Label {
                    text: "Sold: "
                    font.bold: true
                    font.pixelSize: 16
                }

                Label {
                    text: "$" + UserSettings.money.toLocaleString()
                    color: UserSettings.money >= 0 ? Constants.creditColor : Constants.debitColor
                    font.bold: true
                    font.pixelSize: 16
                }

                Label {
                    text: {
                        var awaitingSum = 0
                        for (var i = 0; i < awaitingTransactionModel.count; i++) {
                            awaitingSum += awaitingTransactionModel.getAwaitingTransactionAmount(i)
                        }
                        var virtualTotal = UserSettings.money + awaitingSum
                        return "($" + virtualTotal.toLocaleString() + ")"
                    }
                    color: Material.color(Material.Orange)
                    font.bold: true
                    font.pixelSize: 16
                    visible: awaitingTransactionModel.count > 0
                }
            }

            Image {
                id: logo
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                height: 32
                width: 32
                sourceSize.width: 32
                sourceSize.height: 32
                mipmap: true
                source: "qrc:/icons/icon.png"
                transform: Rotation {
                    id: rotation3d
                    origin.x: logo.width / 2
                    origin.y: logo.height / 2
                    axis { x: 0; y: 1; z: 0 }
                    angle: 0
                }

                PropertyAnimation {
                    target: rotation3d
                    property: "angle"
                    from: 0
                    to: 360
                    duration: 5000
                    loops: Animation.Infinite
                    running: true
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: versionDialog.open()
                }
            }
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
            text: "Awaiting (" + awaitingTransactionModel.count + ")"
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

            ToolBar {
                width: parent.width
                height: 35

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 10

                    SortableLabel {
                        headerText: "Name"
                        sortColumn: EmployeeModel.SortByName
                        sortModel: employeeModel
                        Layout.preferredWidth: 120
                    }

                    SortableLabel {
                        headerText: "Phone"
                        sortColumn: EmployeeModel.SortByPhone
                        sortModel: employeeModel
                        Layout.preferredWidth: 100
                    }

                    SortableLabel {
                        headerText: "Role"
                        sortColumn: EmployeeModel.SortByRole
                        sortModel: employeeModel
                        Layout.preferredWidth: 100
                    }

                    SortableLabel {
                        headerText: "Salary"
                        sortColumn: EmployeeModel.SortBySalary
                        sortModel: employeeModel
                        Layout.preferredWidth: 80
                    }

                    SortableLabel {
                        headerText: "Added Date"
                        sortColumn: EmployeeModel.SortByAddedDate
                        sortModel: employeeModel
                        Layout.preferredWidth: 90
                    }

                    SortableLabel {
                        headerText: "Comment"
                        sortColumn: EmployeeModel.SortByComment
                        sortModel: employeeModel
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

                Column {
                    width: parent.width

                    ListView {
                        id: employeeListView
                        width: parent.width
                        height: parent.parent.height
                        model: employeeModel
                        spacing: 0
                        Label {
                            anchors.centerIn: parent
                            text: "No employees added yet.\nUse File → New Employee to add one."
                            visible: employeeModel.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            color: "gray"
                        }

                        delegate: Rectangle {
                            width: employeeListView.width
                            height: 40
                            color: (index % 2 === 0) ? "#404040" : "#303030"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 5
                                spacing: 10

                                Label {
                                    text: name
                                    font.bold: true
                                    Layout.preferredWidth: 120
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: phone
                                    Layout.preferredWidth: 100
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: role
                                    Layout.preferredWidth: 100
                                    elide: Text.ElideRight
                                }

                                Label {
                                    text: "$" + salary.toLocaleString()
                                    color: "lightgreen"
                                    Layout.preferredWidth: 80
                                }

                                Label {
                                    text: addedDate
                                    Layout.preferredWidth: 90
                                }

                                Label {
                                    text: comment
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                ToolButton {
                                    text: "Pay"
                                    Layout.preferredHeight: 40
                                    onClicked: employeeModel.payEmployee(index)
                                }

                                ToolButton {
                                    text: "Edit"
                                    Layout.preferredHeight: 40
                                    onClicked: {
                                        employeeDialog.editMode = true
                                        employeeDialog.editIndex = index
                                        employeeDialog.loadEmployee(name, phone, role, salary, addedDate, comment)
                                        employeeDialog.open()
                                    }
                                }

                                ToolButton {
                                    text: "Remove"
                                    Layout.preferredHeight: 40
                                    onClicked: employeeModel.removeEntry(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Transaction Tab - Just the list
        Column {
            spacing: 0

            ToolBar {
                width: parent.width
                height: 35

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 10

                    Label {
                        text: "Amount"
                        font.bold: true
                        Layout.preferredWidth: 120
                    }

                    Label {
                        text: "Date"
                        font.bold: true
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: "Description"
                        font.bold: true
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

                Column {
                    width: parent.width

                    ListView {
                        id: transactionListView
                        width: parent.width
                        height: parent.parent.height
                        model: transactionModel
                        spacing: 0
                        Label {
                            anchors.centerIn: parent
                            text: "No transactions added yet.\nUse File → New Transaction to add one."
                            visible: transactionModel.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            color: "gray"
                        }

                        delegate: Rectangle {
                            width: transactionListView.width
                            height: 40
                            color: (index % 2 === 0) ? "#404040" : "#303030"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 5
                                spacing: 10

                                Label {
                                    text: (amount >= 0 ? "+" : "") + "$" + Math.abs(amount).toLocaleString()
                                    color: amount >= 0 ? "lightgreen" : "lightcoral"
                                    font.bold: true
                                    Layout.preferredWidth: 120
                                }

                                Label {
                                    text: date
                                    color: "gray"
                                    Layout.preferredWidth: 100
                                }

                                Label {
                                    text: description
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                ToolButton {
                                    Layout.preferredHeight: 40
                                    text: "Edit"
                                    onClicked: {
                                        transactionDialog.editMode = true
                                        transactionDialog.editIndex = index
                                        transactionDialog.loadTransaction(description, amount, date)
                                        transactionDialog.open()
                                    }
                                }

                                ToolButton {
                                    Layout.preferredHeight: 40
                                    text: "Remove"
                                    onClicked: {
                                        UserSettings.money -= amount
                                        transactionModel.removeEntry(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Awaiting Transactions Tab
        Column {
            spacing: 0

            ToolBar {
                width: parent.width
                height: 35

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 10

                    Label {
                        text: "Amount"
                        font.bold: true
                        Layout.preferredWidth: 120
                    }

                    Label {
                        text: "Date"
                        font.bold: true
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: "Description"
                        font.bold: true
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

                Column {
                    width: parent.width

                    ListView {
                        id: awaitingTransactionListView
                        width: parent.width
                        height: parent.parent.height
                        model: awaitingTransactionModel
                        spacing: 0

                        Label {
                            anchors.centerIn: parent
                            text: "No awaiting transactions.\nTransactions will appear here when clients checkout or employees are paid."
                            visible: awaitingTransactionModel.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            color: "gray"
                        }

                        delegate: Rectangle {
                            width: awaitingTransactionListView.width
                            height: 40
                            color: (index % 2 === 0) ? "#404040" : "#303030"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 5
                                spacing: 10

                                Label {
                                    text: (amount >= 0 ? "+" : "") + "$" + Math.abs(amount).toLocaleString()
                                    color: amount >= 0 ? "lightgreen" : "lightcoral"
                                    font.bold: true
                                    Layout.preferredWidth: 120
                                }

                                Label {
                                    text: date
                                    color: "gray"
                                    Layout.preferredWidth: 100
                                }

                                Label {
                                    text: description
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                ToolButton {
                                    Layout.preferredHeight: 40
                                    text: "Approve"
                                    onClicked: awaitingTransactionModel.approveTransaction(index)
                                }

                                ToolButton {
                                    Layout.preferredHeight: 40
                                    text: "Edit"
                                    onClicked: {
                                        awaitingTransactionDialog.editMode = true
                                        awaitingTransactionDialog.editIndex = index
                                        awaitingTransactionDialog.loadTransaction(description, amount, date)
                                        awaitingTransactionDialog.open()
                                    }
                                }

                                ToolButton {
                                    Layout.preferredHeight: 40
                                    text: "Remove"
                                    onClicked: awaitingTransactionModel.removeEntry(index)
                                }
                            }
                        }
                    }
                }
            }
        }

        // Client Tab - Just the list
        Column {
            spacing: 0

            ToolBar {
                width: parent.width
                height: 35
                //color: Material.accent
                //opacity: 0.3

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 10

                    SortableLabel {
                        headerText: "Type"
                        sortColumn: ClientModel.SortByBusinessType
                        sortModel: clientModel
                        Layout.preferredWidth: 30
                    }

                    SortableLabel {
                        headerText: "Name"
                        sortColumn: ClientModel.SortByName
                        sortModel: clientModel
                        Layout.preferredWidth: 120
                    }

                    SortableLabel {
                        headerText: "Offer"
                        sortColumn: ClientModel.SortByOffer
                        sortModel: clientModel
                        Layout.preferredWidth: 80
                    }

                    SortableLabel {
                        headerText: "Price"
                        sortColumn: ClientModel.SortByPrice
                        sortModel: clientModel
                        Layout.preferredWidth: 60
                    }

                    Label {
                        text: "Supplements"
                        font.bold: true
                        Layout.preferredWidth: 80
                    }

                    SortableLabel {
                        headerText: "Chest"
                        sortColumn: ClientModel.SortByChestID
                        sortModel: clientModel
                        Layout.preferredWidth: 40
                    }

                    SortableLabel {
                        headerText: "Disc"
                        sortColumn: ClientModel.SortByDiscount
                        sortModel: clientModel
                        Layout.preferredWidth: 40
                    }

                    SortableLabel {
                        headerText: "Phone"
                        sortColumn: ClientModel.SortByPhone
                        sortModel: clientModel
                        Layout.preferredWidth: 100
                    }

                    SortableLabel {
                        headerText: "Comment"
                        sortColumn: ClientModel.SortByComment
                        sortModel: clientModel
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

                Column {
                    width: parent.width

                    ListView {
                        id: clientListView
                        width: parent.width
                        height: parent.parent.height //- 35
                        model: clientModel
                        spacing: 0
                        Label {
                            anchors.centerIn: parent
                            text: "No clients added yet.\nUse File → New Client to add one."
                            visible: clientModel.count === 0
                            horizontalAlignment: Text.AlignHCenter
                            color: "gray"
                        }

                        delegate: Rectangle {
                            width: clientListView.width
                            height: 40
                            color: (index % 2 === 0) ? "#404040" : "#303030"  // Mid grey for even, dark grey for odd

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
                                    Layout.preferredHeight: 40
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
                                    Layout.preferredHeight: 40
                                    onClicked: clientModel.checkout(index)
                                }

                                ToolButton {
                                    text: "Edit"
                                    Layout.preferredHeight: 40
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
                                    Layout.preferredHeight: 40
                                    onClicked: clientModel.removeEntry(index)
                                }
                            }
                        }
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
                flat: true
                text: "OK"
                visible: supplementDialog.readOnly
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: supplementDialog.close()
            }

            Button {
                flat: true
                text: "Apply"
                visible: !supplementDialog.readOnly
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    clientDialog.selectedSupplements = supplementDialog.getSelectedSupplements()
                    supplementDialog.close()
                }
            }

            Button {
                flat: true
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
        anchors.centerIn: parent
        modal: true

        property bool editMode: false
        property int editIndex: -1

        function loadEmployee(name, phone, role, salary, addedDate, comment) {
            empName.text = name
            empPhone.text = phone
            empRole.text = role
            empSalary.value = salary
            empAddedDate.text = addedDate
            empComment.text = comment
        }

        function clearFields() {
            empName.clear()
            empPhone.clear()
            empRole.clear()
            empSalary.value = 50000
            empAddedDate.text = Qt.formatDateTime(new Date(), "yyyy-MM-dd")
            empComment.clear()
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
                value: 50000
                editable: true
                //textFromValue: function(value, locale) {
                //    return "$" + value.toLocaleString(locale, 'f', 0)
                //}
            }

            Label { text: "Added Date:" }
            TextField {
                Layout.preferredHeight: Constants.comboHeight
                id: empAddedDate
                Layout.fillWidth: true
                placeholderText: "YYYY-MM-DD"
                text: Qt.formatDateTime(new Date(), "yyyy-MM-dd")
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

        footer: DialogButtonBox {
            Button {
                flat: true
                text: employeeDialog.editMode ? "Update" : "Add"
                enabled: empName.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    if (employeeDialog.editMode) {
                        employeeModel.updateEmployee(employeeDialog.editIndex, empName.text,
                                                     empPhone.text, empRole.text, empSalary.value,
                                                     empAddedDate.text, empComment.text)
                    } else {
                        employeeModel.addEmployee(empName.text, empPhone.text,
                                                  empRole.text, empSalary.value,
                                                  empAddedDate.text, empComment.text)
                    }
                    employeeDialog.close()
                }
            }
            Button {
                flat: true
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
                editable: true
                //textFromValue: function(value, locale) {
                //    return "$" + value.toLocaleString(locale, 'f', 0)
                //}
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
                flat: true
                text: transactionDialog.editMode ? "Update" : "Add"
                enabled: transDesc.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    if (transactionDialog.editMode) {
                        // Get the old amount and calculate difference
                        var oldAmount = transactionModel.getTransactionAmount(transactionDialog.editIndex)
                        var difference = transAmount.value - oldAmount
                        UserSettings.money += difference

                        transactionModel.updateTransaction(transactionDialog.editIndex, transDesc.text,
                                                           transAmount.value, transDate.text)
                    } else {
                        awaitingTransactionModel.addAwaitingTransaction(transDesc.text, transAmount.value, transDate.text)
                    }
                    transactionDialog.close()
                }
            }
            Button {
                flat: true
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: transactionDialog.close()
            }
        }
    }

    // Awaiting Transaction Dialog
    Dialog {
        id: awaitingTransactionDialog
        title: editMode ? "Edit Awaiting Transaction" : "Add New Awaiting Transaction"
        width: 400
        anchors.centerIn: parent
        modal: true

        property bool editMode: false
        property int editIndex: -1

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
                text: awaitingTransactionDialog.editMode ? "Update" : "Add"
                enabled: awaitingTransDesc.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    if (awaitingTransactionDialog.editMode) {
                        awaitingTransactionModel.updateAwaitingTransaction(awaitingTransactionDialog.editIndex,
                                                                           awaitingTransDesc.text,
                                                                           awaitingTransAmount.value,
                                                                           awaitingTransDate.text)
                    } else {
                        awaitingTransactionModel.addAwaitingTransaction(awaitingTransDesc.text,
                                                                        awaitingTransAmount.value,
                                                                        awaitingTransDate.text)
                    }
                    awaitingTransactionDialog.close()
                }
            }
            Button {
                flat: true
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: awaitingTransactionDialog.close()
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

            Label { text: "Chest ID:" }
            SpinBox {
                Layout.preferredHeight: Constants.comboHeight
                id: clientChestID
                Layout.fillWidth: true
                from: 1
                to: 999
                value: 1
                editable: true
            }

            Label { text: "Discount (%):" }
            SpinBox {
                Layout.preferredHeight: Constants.comboHeight
                id: clientDiscount
                Layout.fillWidth: true
                from: -100
                to: 100
                value: 0
                editable: true
            }

            Label { text: "Phone:" }
            TextField {
                Layout.preferredHeight: Constants.comboHeight
                id: clientPhone
                Layout.fillWidth: true
                placeholderText: "+1234567890"
            }

            Label { text: "Offer:" }
            ComboBox {
                Layout.preferredHeight: Constants.comboHeight
                id: clientOfferCombo
                Layout.fillWidth: true
                model: ["Bronze", "Silver", "Gold"]
            }

            Label { text: "Supplements:" }
            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                Label {
                    text: clientDialog.selectedSupplements.length + " selected"
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

            Label { text: "Final Price:" }
            RowLayout {
                Item {
                    Layout.fillWidth: true
                }

                Label {
                    id: calculatedPrice
                    Layout.preferredHeight: Constants.comboHeight
                    Layout.preferredWidth: implicitWidth + 20
                    text: "$" + (clientModel.calculatePrice(
                                     clientOfferCombo.currentIndex,
                                     clientDialog.selectedSupplements,
                                     clientDiscount.value
                                     )).toFixed(2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

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

        footer: DialogButtonBox {
            Button {
                flat: true
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
                flat: true
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
                flat: true
                text: "Clear All"
                DialogButtonBox.buttonRole: DialogButtonBox.DestructiveRole
                onClicked: {
                    employeeModel.clear()
                    transactionModel.clear()
                    awaitingTransactionModel.clear()
                    clientModel.clear()
                    UserSettings.money = 0
                    clearAllDialog.close()
                }
            }
            Button {
                flat: true
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: clearAllDialog.close()
            }
        }
    }
}
