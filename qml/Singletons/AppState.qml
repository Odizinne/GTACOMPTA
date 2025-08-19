pragma Singleton

import QtQuick

QtObject {
    // Models (will be set from Main.qml)
    property var employeeModel: null
    property var transactionModel: null
    property var awaitingTransactionModel: null
    property var clientModel: null
    property var supplementModel: null
    property var offerModel: null

    // Filter models (will be set from Main.qml)
    property var employeeFilterModel: null
    property var transactionFilterModel: null
    property var awaitingTransactionFilterModel: null
    property var clientFilterModel: null

    // App state
    property string filterText: ""
    property bool isWasm: Qt.platform.os === "wasm"

    // Dialogs (will be set from Main.qml)
    property var employeeDialog: null
    property var transactionDialog: null
    property var awaitingTransactionDialog: null
    property var clientDialog: null
    property var confirmDialog: null
    property var supplementDialog: null

    // Helper functions
    function toUiPrice(priceInCents) {
        return "$" + (priceInCents).toLocaleString()
    }

    function toModelPrice(priceString) {
        return parseInt(priceString.replace(/\D/g, ''), 10)
    }

    function getSourceIndex(filterModel, index) {
        return filterModel.mapToSource(filterModel.index(index, 0))
    }
}
