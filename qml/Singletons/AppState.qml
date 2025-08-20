pragma Singleton

import QtQuick

QtObject {
    property var employeeModel: null
    property var transactionModel: null
    property var awaitingTransactionModel: null
    property var clientModel: null
    property var supplementModel: null
    property var offerModel: null

    property var employeeFilterModel: null
    property var transactionFilterModel: null
    property var awaitingTransactionFilterModel: null
    property var clientFilterModel: null

    property string filterText: ""
    property bool isWasm: Qt.platform.os === "wasm"

    property var employeeDialog: null
    property var transactionDialog: null
    property var awaitingTransactionDialog: null
    property var clientDialog: null
    property var confirmDialog: null
    property var supplementDialog: null

    function toUiPrice(price) {
        if (price === 0) return "$0"
        var sign = price > 0 ? "+" : "-"
        var absolutePrice = Math.abs(price)
        return sign + "$" + absolutePrice.toLocaleString()
    }

    function toModelPrice(priceString) {
        return parseInt(priceString.replace(/\D/g, ''), 10)
    }

    function getSourceIndex(filterModel, index) {
        return filterModel.mapToSource(filterModel.index(index, 0))
    }
}
