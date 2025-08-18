import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.impl
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

    property string filterText: ""

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

    SupplementModel {
        id: supplementModel
        Component.onCompleted: loadFromFile()
    }

    OfferModel {
        id: offerModel
        Component.onCompleted: loadFromFile()
    }

    // Filter proxy models
    FilterProxyModel {
        id: employeeFilterModel
        sourceModel: employeeModel
        filterText: window.filterText
    }

    FilterProxyModel {
        id: transactionFilterModel
        sourceModel: transactionModel
        filterText: window.filterText
    }

    FilterProxyModel {
        id: awaitingTransactionFilterModel
        sourceModel: awaitingTransactionModel
        filterText: window.filterText
    }

    FilterProxyModel {
        id: clientFilterModel
        sourceModel: clientModel
        filterText: window.filterText
    }

    FakeUpgradeDialog {
        Material.roundedScale: Material.ExtraSmallScale

        id: fakeUpgradeDialog
    }

    WelcomeDialog {
        Material.roundedScale: Material.ExtraSmallScale

        id: welcomeDialog
    }

    VersionDialog {
        Material.roundedScale: Material.ExtraSmallScale

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

    // Header with menu
    header: ToolBar {
        height: 41
        Material.primary: Material.dialogColor
        Item {
            anchors.fill: parent
            MenuBar {
                anchors.left: parent.left
                height: 41
                Menu {
                    title: "File"

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
                    title: "Databases"
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
                        text: "Supplements and Offers..."
                        onTriggered: supplementOfferManagementDialog.open()
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
                    text: UserSettings.companyName + " - " + "Balance: "
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

            IconImage {
                anchors.right: filterField.left
                anchors.rightMargin: 5
                sourceSize.width: 20
                sourceSize.height: 20
                height: 20
                width: 20
                color: filterField.activeFocus ? Material.accent : Material.hintTextColor
                anchors.verticalCenter: parent.verticalCenter
                source: "qrc:/icons/search.svg"
                Behavior on color {
                    ColorAnimation {
                        duration: 200
                        easing.type: Easing.OutQuad
                    }
                }
            }

            TextField {
                id: filterField
                anchors.right: logo.left
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                height: 35
                width: 180
                placeholderText: "Filter..."
                onTextChanged: window.filterText = text
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
            text: "Employees (" + (filterText ? employeeFilterModel.rowCount() + "/" + employeeModel.count : employeeModel.count) + ")"
        }
        TabButton {
            text: "Transactions (" + (filterText ? transactionFilterModel.rowCount() + "/" + transactionModel.count : transactionModel.count) + ")"
        }
        TabButton {
            text: "Awaiting (" + (filterText ? awaitingTransactionFilterModel.rowCount() + "/" + awaitingTransactionModel.count : awaitingTransactionModel.count) + ")"
        }
        TabButton {
            text: "Clients (" + (filterText ? clientFilterModel.rowCount() + "/" + clientModel.count : clientModel.count) + ")"
        }
    }

    // Replace your existing StackLayout section with this StackView implementation

    StackView {
        id: stackView
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        // Simple fade transitions
        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

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

        // Create components for each tab
        Component {
            id: employeeComponent

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

                    ListView {
                        id: employeeListView
                        width: parent.width
                        height: parent.parent.height
                        model: employeeFilterModel
                        spacing: 0

                        Label {
                            anchors.centerIn: parent
                            text: filterText ? "No employees match the filter." : "No employees added yet.\nUse Databases → New Employee to add one."
                            visible: employeeListView.count === 0
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

                                RowLayout {
                                    spacing: 0
                                    ToolButton {
                                        text: "Pay"
                                        Layout.preferredHeight: 40
                                        icon.source: "qrc:/icons/dollar.svg"
                                        icon.width: 16
                                        icon.height: 16
                                        icon.color: Material.color(Material.Orange)
                                        onClicked: {
                                            var sourceIndex = employeeFilterModel.mapToSource(employeeFilterModel.index(index, 0))
                                            employeeModel.payEmployee(sourceIndex.row)
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
                                            var sourceIndex = employeeFilterModel.mapToSource(employeeFilterModel.index(index, 0))
                                            employeeDialog.editMode = true
                                            employeeDialog.editIndex = sourceIndex.row
                                            employeeDialog.loadEmployee(name, phone, role, salary, addedDate, comment)
                                            employeeDialog.open()
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
                                            var sourceIndex = employeeFilterModel.mapToSource(employeeFilterModel.index(index, 0))
                                            employeeModel.removeEntry(sourceIndex.row)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: transactionComponent

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

                    ListView {
                        id: transactionListView
                        width: parent.width
                        height: parent.parent.height
                        model: transactionFilterModel
                        spacing: 0

                        Label {
                            anchors.centerIn: parent
                            text: filterText ? "No transactions match the filter." : "No transactions added yet.\nUse Databases → New Transaction to add one."
                            visible: transactionListView.count === 0
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
                                            var sourceIndex = transactionFilterModel.mapToSource(transactionFilterModel.index(index, 0))
                                            transactionDialog.editMode = true
                                            transactionDialog.editIndex = sourceIndex.row
                                            transactionDialog.loadTransaction(description, amount, date)
                                            transactionDialog.open()
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
                                            var sourceIndex = transactionFilterModel.mapToSource(transactionFilterModel.index(index, 0))
                                            UserSettings.money -= amount
                                            transactionModel.removeEntry(sourceIndex.row)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: awaitingComponent

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

                    ListView {
                        id: awaitingTransactionListView
                        width: parent.width
                        height: parent.parent.height
                        model: awaitingTransactionFilterModel
                        spacing: 0

                        Label {
                            anchors.centerIn: parent
                            text: filterText ? "No awaiting transactions match the filter." : "No awaiting transactions.\nTransactions will appear here when clients checkout or employees are paid."
                            visible: awaitingTransactionListView.count === 0
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

                                RowLayout {
                                    spacing: 0
                                    ToolButton {
                                        Layout.preferredHeight: 40
                                        text: "Approve"
                                        icon.source: "qrc:/icons/checkmark.svg"
                                        icon.width: 16
                                        icon.height: 16
                                        icon.color: Material.color(Material.Green)
                                        onClicked: {
                                            var sourceIndex = awaitingTransactionFilterModel.mapToSource(awaitingTransactionFilterModel.index(index, 0))
                                            awaitingTransactionModel.approveTransaction(sourceIndex.row)
                                        }
                                    }

                                    ToolButton {
                                        Layout.preferredHeight: 40
                                        text: "Edit"
                                        icon.source: "qrc:/icons/edit.svg"
                                        icon.width: 16
                                        icon.height: 16
                                        icon.color: Material.color(Material.Blue)
                                        onClicked: {
                                            var sourceIndex = awaitingTransactionFilterModel.mapToSource(awaitingTransactionFilterModel.index(index, 0))
                                            awaitingTransactionDialog.editMode = true
                                            awaitingTransactionDialog.editIndex = sourceIndex.row
                                            awaitingTransactionDialog.loadTransaction(description, amount, date)
                                            awaitingTransactionDialog.open()
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
                                            var sourceIndex = awaitingTransactionFilterModel.mapToSource(awaitingTransactionFilterModel.index(index, 0))
                                            awaitingTransactionModel.removeEntry(sourceIndex.row)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Component {
            id: clientComponent

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

                    ListView {
                        id: clientListView
                        width: parent.width
                        height: parent.parent.height
                        model: clientFilterModel
                        spacing: 0

                        Label {
                            anchors.centerIn: parent
                            text: filterText ? "No clients match the filter." : "No clients added yet.\nUse Databases → New Client to add one."
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
                                        if (offer >= 0 && offer < offerModel.count) {
                                            return offerModel.getOfferName(offer)
                                        }
                                        return "Unknown"
                                    }
                                    Layout.preferredWidth: 80
                                }

                                Label {
                                    text: "$" + (price / 100).toFixed(2)
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
                                            var sourceIndex = clientFilterModel.mapToSource(clientFilterModel.index(index, 0))
                                            clientModel.checkout(sourceIndex.row)
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
                                            var sourceIndex = clientFilterModel.mapToSource(clientFilterModel.index(index, 0))
                                            clientDialog.editMode = true
                                            clientDialog.editIndex = sourceIndex.row
                                            clientDialog.loadClient(businessType, name, offer, price,
                                                                    supplements, chestID, discount, phoneNumber, comment)
                                            clientDialog.open()
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
                                            var sourceIndex = clientFilterModel.mapToSource(clientFilterModel.index(index, 0))
                                            clientModel.removeEntry(sourceIndex.row)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Initialize with the first tab
        initialItem: employeeComponent
    }

    // Handle tab changes
    Connections {
        target: tabBar
        function onCurrentIndexChanged() {
            var components = [employeeComponent, transactionComponent, awaitingComponent, clientComponent]

            if (tabBar.currentIndex < components.length) {
                // Replace current item with new one
                if (stackView.depth === 0) {
                    stackView.push(components[tabBar.currentIndex])
                } else {
                    stackView.replace(components[tabBar.currentIndex])
                }
            }
        }
    }

    Dialog {
        Material.roundedScale: Material.ExtraSmallScale
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
                    selected.push(i)
                }
            }
            return selected
        }

        function setSelectedSupplements(supplements) {
            for (var i = 0; i < supplementRepeater.count; i++) {
                var checkbox = supplementRepeater.itemAt(i)
                checkbox.checked = supplements.includes(i)
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
                        text: model.name + " - $" + (model.price / 100).toFixed(2)

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
            Repeater {
                model: supplementDialog.readOnly ? [
                                                       {text: "OK", role: DialogButtonBox.AcceptRole, action: function() { supplementDialog.close() }}
                                                   ] : [
                                                       {text: "Apply", role: DialogButtonBox.AcceptRole, action: function() {
                                                           clientDialog.selectedSupplements = supplementDialog.getSelectedSupplements()
                                                           supplementDialog.close()
                                                       }},
                                                       {text: "Cancel", role: DialogButtonBox.RejectRole, action: function() { supplementDialog.close() }}
                                                   ]

                Button {
                    flat: true
                    text: modelData.text
                    DialogButtonBox.buttonRole: modelData.role
                    onClicked: modelData.action()
                }
            }
        }
    }

    // Employee Dialog
    Dialog {
        Material.roundedScale: Material.ExtraSmallScale
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
        Material.roundedScale: Material.ExtraSmallScale
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
        Material.roundedScale: Material.ExtraSmallScale
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
        Material.roundedScale: Material.ExtraSmallScale
        id: clientDialog
        title: editMode ? "Edit Client" : "Add New Client"
        width: 500
        anchors.centerIn: parent
        modal: true

        property bool editMode: false
        property int editIndex: -1
        property var selectedSupplements: []

        function calculatePrice() {
            var basePrice = 0
            if (clientOfferCombo.currentIndex >= 0 && clientOfferCombo.currentIndex < offerModel.count) {
                basePrice = offerModel.getOfferPrice(clientOfferCombo.currentIndex)
            }

            var supplementsTotal = 0
            for (var i = 0; i < selectedSupplements.length; i++) {
                var suppIndex = selectedSupplements[i]
                if (suppIndex >= 0 && suppIndex < supplementModel.count) {
                    supplementsTotal += supplementModel.getSupplementPrice(suppIndex)
                }
            }

            var totalBeforeDiscount = basePrice + supplementsTotal
            var finalPrice = totalBeforeDiscount * (100 - clientDiscount.value) / 100

            return finalPrice
        }

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
                onValueChanged: calculatedPrice.updatePrice()
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
                model: offerModel
                textRole: "name"
                onCurrentIndexChanged: calculatedPrice.updatePrice()
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
                    text: "$" + (clientDialog.calculatePrice() / 100).toFixed(2)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    function updatePrice() {
                        text = "$" + (clientDialog.calculatePrice() / 100).toFixed(2)
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
            target: clientDialog
            function onSelectedSupplementsChanged() {
                calculatedPrice.updatePrice()
            }
        }

        footer: DialogButtonBox {
            Button {
                flat: true
                text: clientDialog.editMode ? "Update" : "Add"
                enabled: clientName.text.length > 0
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
                onClicked: {
                    var calculatedPriceValue = clientDialog.calculatePrice()

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
        Material.roundedScale: Material.ExtraSmallScale
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

    // Supplement and Offer Management Dialog
    Dialog {
        Material.roundedScale: Material.ExtraSmallScale
        id: supplementOfferManagementDialog
        title: "Manage Supplements & Offers"
        width: 800
        height: 600
        anchors.centerIn: parent
        modal: true

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
                    text: "Supplements (" + supplementModel.count + ")"
                }
                TabButton {
                    text: "Offers (" + offerModel.count + ")"
                }
            }
        }

        StackView {
            id: managementStackView
            anchors.top: headerRow.bottom
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 4

            // Fade transitions
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
                        model: supplementModel
                        spacing: 5

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
                                    text: "$" + (model.price / 100).toFixed(2)
                                    color: "lightgreen"
                                    Layout.preferredWidth: 80
                                }

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
                                    onClicked: supplementModel.removeEntry(index)
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
                        model: offerModel
                        spacing: 5

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
                                    text: "$" + (model.price / 100).toFixed(2)
                                    color: "lightgreen"
                                    Layout.preferredWidth: 80
                                }

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
                                    onClicked: offerModel.removeEntry(index)
                                }
                            }
                        }
                    }
                }
            }

            initialItem: supplementsTab
        }

        // Handle tab changes for management dialog
        Connections {
            target: managementTabBar
            function onCurrentIndexChanged() {
                var tabs = [supplementsTab, offersTab]
                if (managementTabBar.currentIndex < tabs.length) {
                    managementStackView.replace(tabs[managementTabBar.currentIndex])
                }
            }
        }

        footer: DialogButtonBox {
            Button {
                flat: true
                text: "Close"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
                onClicked: supplementOfferManagementDialog.close()
            }
        }
    }

    Dialog {
        Material.roundedScale: Material.ExtraSmallScale
        id: supplementOfferDialog
        title: editMode ? ("Edit " + (isOffer ? "Offer" : "Supplement")) : ("Add New " + (isOffer ? "Offer" : "Supplement"))
        width: 400
        anchors.centerIn: parent
        modal: true

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
                textFromValue: function(value, locale) {
                    return "$" + (value / 100).toFixed(2)
                }
                valueFromText: function(text, locale) {
                    return Math.round(parseFloat(text.replace('$', '')) * 100)
                }
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
                            offerModel.updateOffer(supplementOfferDialog.editIndex, itemName.text, itemPrice.value)
                        } else {
                            supplementModel.updateSupplement(supplementOfferDialog.editIndex, itemName.text, itemPrice.value)
                        }
                    } else {
                        if (supplementOfferDialog.isOffer) {
                            offerModel.addOffer(itemName.text, itemPrice.value)
                        } else {
                            supplementModel.addSupplement(itemName.text, itemPrice.value)
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
}
