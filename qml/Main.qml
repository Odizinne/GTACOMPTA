import QtQuick
import QtQuick.Controls.Material
import QtQuick.Dialogs
import QtQml
import Odizinne.GTACOMPTA

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 720
    minimumWidth: 1280
    minimumHeight: 720
    title: "GTACOMPTA"
    Material.theme: UserSettings.darkMode ? Material.Dark : Material.Light
    Material.primary: Constants.primaryColor
    Material.background: Constants.backgroundColor
    Material.accent: Constants.accentColor
    color: Constants.surfaceColor

    Component.onCompleted: {
        RemoteDatabaseManager

        AppState.employeeModel = employeeModel
        AppState.transactionModel = transactionModel
        AppState.awaitingTransactionModel = awaitingTransactionModel
        AppState.clientModel = clientModel
        AppState.supplementModel = supplementModel
        AppState.offerModel = offerModel
        AppState.companySummaryModel = companySummaryModel
        AppState.employeeFilterModel = employeeFilterModel
        AppState.transactionFilterModel = transactionFilterModel
        AppState.awaitingTransactionFilterModel = awaitingTransactionFilterModel
        AppState.clientFilterModel = clientFilterModel
        AppState.employeeDialog = employeeDialog
        AppState.transactionDialog = transactionDialog
        AppState.awaitingTransactionDialog = awaitingTransactionDialog
        AppState.clientDialog = clientDialog
        AppState.confirmDialog = confirmDialog
        AppState.supplementDialog = supplementDialog
    }

    // Models
    EmployeeModel {
        id: employeeModel
        Component.onCompleted: loadFromFile(UserSettings.useRemoteDatabase)
    }

    TransactionModel {
        id: transactionModel
        Component.onCompleted: loadFromFile(UserSettings.useRemoteDatabase)
    }

    AwaitingTransactionModel {
        id: awaitingTransactionModel
        Component.onCompleted: loadFromFile(UserSettings.useRemoteDatabase)
    }

    ClientModel {
        id: clientModel
        Component.onCompleted: loadFromFile(UserSettings.useRemoteDatabase)
    }

    SupplementModel {
        id: supplementModel
        Component.onCompleted: loadFromFile(UserSettings.useRemoteDatabase)
    }

    OfferModel {
        id: offerModel
        Component.onCompleted: loadFromFile(UserSettings.useRemoteDatabase)
    }

    CompanySummaryModel {
        id: companySummaryModel
        Component.onCompleted: {
            loadFromFile(UserSettings.useRemoteDatabase)
        }

        // Monitor when model finishes loading
        onCountChanged: {
            checkIfShouldShowWelcome()
        }

        onCompanyNameChanged: {
            checkIfShouldShowWelcome()
        }

        function checkIfShouldShowWelcome() {
            if (!UserSettings.useRemoteDatabase && mainStack.currentItem === mainPage) {
                var isEmpty = companySummaryModel.count === 0
                var noCompanyName = !companySummaryModel.companyName || companySummaryModel.companyName.length === 0

                if (isEmpty || noCompanyName) {
                    console.log("Company model is empty - showing welcome dialog")
                    welcomeDialog.open()
                }
            }
        }
    }

    // Filter proxy models
    FilterProxyModel {
        id: employeeFilterModel
        sourceModel: employeeModel
        filterText: AppState.filterText
    }

    FilterProxyModel {
        id: transactionFilterModel
        sourceModel: transactionModel
        filterText: AppState.filterText
    }

    FilterProxyModel {
        id: awaitingTransactionFilterModel
        sourceModel: awaitingTransactionModel
        filterText: AppState.filterText
    }

    FilterProxyModel {
        id: clientFilterModel
        sourceModel: clientModel
        filterText: AppState.filterText
    }

    // Model connections
    Connections {
        target: clientModel
        function onCheckoutCompleted(description, amount) {
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

    // In Main.qml, update this connection:
    Connections {
        target: transactionModel
        function onRowsInserted(parent, first, last) {
            for (var i = first; i <= last; i++) {
                var amount = transactionModel.getTransactionAmount(i)
                companySummaryModel.addToMoney(amount)  // Use companySummaryModel instead of UserSettings
            }
        }
    }

    StackView {
        id: mainStack
        anchors.fill: parent
        initialItem: splash

        pushEnter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 210; easing.type: Easing.InQuint }
                NumberAnimation { property: "y"; from: (mainStack.mirrored ? -0.3 : 0.3) * mainStack.width; to: 0; duration: 270; easing.type: Easing.OutCubic }
            }
        }
        pushExit: Transition {
            NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 150; easing.type: Easing.OutQuint }
        }

        Connections {
            target: splash
            function onLoadingFinished() {
                mainStack.push(mainPage)
                if (UserSettings.firstRun) {
                    welcomeDialog.open()
                }
            }
        }
    }

    SplashScreen {
        id: splash
    }

    MainPage {
        id: mainPage
        visible: false
        onShowSettings: settingsDialog.open()
        onShowNotes: notesDialog.open()
        onShowFakeUpgrade: fakeUpgradeDialog.open()
        onShowVersion: versionDialog.open()
        onShowNewEmployee: employeeDialog.open()
        onShowNewTransaction: transactionDialog.open()
        onShowNewClient: clientDialog.open()
        onShowSupplementOfferManagement: supplementOfferManagementDialog.open()
        onShowExport: exportDialog.open()
        onShowImport: importDialog.open()
        onClearAllData: clearAllDialog.open()
    }

    // All dialogs
    SettingsDialog {
        id: settingsDialog
    }

    NotesDialog {
        id: notesDialog
    }

    FakeUpgradeDialog {
        id: fakeUpgradeDialog
    }

    VersionDialog {
        id: versionDialog
    }

    EmployeeDialog {
        id: employeeDialog
        onEmployeeAdded: function(name, phone, role, salary, addedDate, comment) {
            employeeModel.addEmployee(name, phone, role, salary, addedDate, comment)
        }
        onEmployeeUpdated: function(index, name, phone, role, salary, addedDate, comment) {
            employeeModel.updateEmployee(index, name, phone, role, salary, addedDate, comment)
        }
    }

    TransactionDialog {
        id: transactionDialog
        onTransactionAdded: function(description, amount, date, skip) {
            if (skip) {
                transactionModel.addTransaction(description, amount, date)
            } else {
                awaitingTransactionModel.addAwaitingTransaction(description, amount, date)
            }
        }
        onTransactionUpdated: function(index, description, amount, date) {
            var oldAmount = transactionModel.getTransactionAmount(index)
            var difference = amount - oldAmount
            companySummaryModel.addToMoney(difference)  // Use companySummaryModel
            transactionModel.updateTransaction(index, description, amount, date)
        }
    }

    AwaitingTransactionDialog {
        id: awaitingTransactionDialog
        onAwaitingTransactionAdded: function(description, amount, date) {
            awaitingTransactionModel.addAwaitingTransaction(description, amount, date)
        }
        onAwaitingTransactionUpdated: function(index, description, amount, date) {
            awaitingTransactionModel.updateAwaitingTransaction(index, description, amount, date)
        }
    }

    ClientDialog {
        id: clientDialog
        onClientAdded: function(businessType, name, offer, price, supplementQuantities, discount, phoneNumber, comment) {
            clientModel.addClientWithQuantities(businessType, name, offer, price, supplementQuantities, discount, phoneNumber, comment)
        }
        onClientUpdated: function(index, businessType, name, offer, price, supplementQuantities, discount, phoneNumber, comment) {
            clientModel.updateClientWithQuantities(index, businessType, name, offer, price, supplementQuantities, discount, phoneNumber, comment)
        }
        onSupplementManagementRequested: {
            supplementOfferManagementDialog.open()
        }
    }

    SupplementOfferManagementDialog {
        id: supplementOfferManagementDialog
        onSupplementAdded: function(name, price) {
            supplementModel.addSupplement(name, price)
        }
        onSupplementUpdated: function(index, name, price) {
            supplementModel.updateSupplement(index, name, price)
        }
        onOfferAdded: function(name, price) {
            offerModel.addOffer(name, price)
        }
        onOfferUpdated: function(index, name, price) {
            offerModel.updateOffer(index, name, price)
        }
        onSupplementRemoved: function(index) {
            supplementModel.removeEntry(index)
        }
        onOfferRemoved: function(index) {
            offerModel.removeEntry(index)
        }
    }

    ExportDialog {
        id: exportDialog
        onExportRequested: function(filePath) {
            if (AppState.isWasm) {
                DataManager.exportDataToString(employeeModel, transactionModel, awaitingTransactionModel,
                                             clientModel, supplementModel, offerModel, companySummaryModel)
            } else {
                DataManager.exportData(filePath, employeeModel, transactionModel, awaitingTransactionModel,
                                     clientModel, supplementModel, offerModel, companySummaryModel)
            }
        }
    }

    ImportDialog {
        id: importDialog
        onImportRequested: function(filePath) {
            if (AppState.isWasm) {
                WasmFileHandler.openLoadDialog()
            } else {
                DataManager.importData(filePath, employeeModel, transactionModel, awaitingTransactionModel,
                                     clientModel, supplementModel, offerModel, companySummaryModel)
            }
        }
    }

    ClearAllDialog {
        id: clearAllDialog
        onClearAllConfirmed: {
            employeeModel.clear()
            transactionModel.clear()
            awaitingTransactionModel.clear()
            clientModel.clear()
            offerModel.clear()
            supplementModel.clear()
            UserSettings.money = 0
        }
    }

    WelcomeDialog {
        id: welcomeDialog
        onAccepted: {
            if (!UserSettings.useRemoteDatabase) {
                transactionModel.addTransaction("Initial transfer", welcomeDialog.initialAmount, Qt.formatDateTime(new Date(), "yyyy-MM-dd"))
            }
        }
    }

    ConfirmDialog {
        id: confirmDialog
    }

    MessageDialog {
        id: messageDialog
    }

    SupplementSelectionDialog {
        id: supplementDialog
    }

    Connections {
        target: AppState.isWasm ? WasmFileHandler : null
        function onLoadFileSelected(content) {
            DataManager.importDataFromString(content, employeeModel, transactionModel, awaitingTransactionModel,
                                           clientModel, supplementModel, offerModel, companySummaryModel)
        }
    }

    Connections {
        target: DataManager
        enabled: AppState.isWasm
        function onExportDataReady(data, fileName) {
            WasmFileHandler.openSaveDialog(fileName, data)
        }
    }

    Connections {
        target: DataManager
        function onExportCompleted(success, message) {
            messageDialog.show(success, message)
        }
        function onImportCompleted(success, message) {
            messageDialog.show(success, message)
            if (success) {
                employeeModel.loadFromFile(UserSettings.useRemoteDatabase)
                transactionModel.loadFromFile(UserSettings.useRemoteDatabase)
                awaitingTransactionModel.loadFromFile(UserSettings.useRemoteDatabase)
                clientModel.loadFromFile(UserSettings.useRemoteDatabase)
                supplementModel.loadFromFile(UserSettings.useRemoteDatabase)
                offerModel.loadFromFile(UserSettings.useRemoteDatabase)
            }
        }
        function onSettingsChanged(money, firstRun, companyName, notes, volume) {
            UserSettings.money = money
            UserSettings.firstRun = firstRun
            UserSettings.companyName = companyName
            UserSettings.notes = notes
            UserSettings.volume = volume
        }
    }
}
