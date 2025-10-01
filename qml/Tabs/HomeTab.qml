pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Column {
    spacing: 0
    id: root

    property real weeklyIncome: 0
    property real weeklyOutcome: 0
    property real weeklyRevenue: 0

    property var weeklyTotals: []
    property real maxAbsValue: 0

    ListModel {
        id: weeksDisplayModel
    }

    // Hidden repeaters to calculate sums
    Repeater {
        id: clientRepeater
        model: AppState.clientModel
        delegate: Item {
            required property real price
            Component.onCompleted: root.weeklyIncome += price
        }
    }

    Repeater {
        id: employeeRepeater
        model: AppState.employeeModel
        delegate: Item {
            required property int salary
            Component.onCompleted: root.weeklyOutcome += salary
        }
    }

    function getMonday(date) {
        var d = new Date(date)
        var day = d.getDay()
        var diff = d.getDate() - day + (day === 0 ? -6 : 1)
        d.setDate(diff)
        d.setHours(0, 0, 0, 0)
        return d
    }

    function getWeekKey(date) {
        var monday = getMonday(date)
        return monday.toISOString().split('T')[0]
    }

    function formatWeekLabel(dateStr) {
        var date = new Date(dateStr)
        var monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        return monthNames[date.getMonth()] + " " + date.getDate()
    }

    function getLastTransaction() {
        if (!AppState.transactionModel || AppState.transactionModel.count === 0) {
            return null
        }

        var latestDate = null
        var latestIndex = -1

        // Iterate backwards to get the "last" transaction more naturally
        for (var i = AppState.transactionModel.count - 1; i >= 0; i--) {
            var index = AppState.transactionModel.index(i, 0)
            var dateStr = AppState.transactionModel.data(index, TransactionModel.DateRole)

            if (!dateStr) continue

            var date = new Date(dateStr)

            if (!latestDate || date > latestDate) {
                latestDate = date
                latestIndex = i
            }
        }

        if (latestIndex === -1) return null

        var idx = AppState.transactionModel.index(latestIndex, 0)
        return {
            description: AppState.transactionModel.data(idx, TransactionModel.DescriptionRole),
            amount: AppState.transactionModel.data(idx, TransactionModel.AmountRole),
            date: AppState.transactionModel.data(idx, TransactionModel.DateRole)
        }
    }

    function scanTransactions() {
        if (!AppState.transactionModel) return

        var weeks = {}
        var oldestDate = new Date()
        var hasData = false

        // Scan all transactions and sum by week
        for (var i = 0; i < AppState.transactionModel.count; i++) {
            var index = AppState.transactionModel.index(i, 0)
            var dateStr = AppState.transactionModel.data(index, TransactionModel.DateRole)
            var amount = AppState.transactionModel.data(index, TransactionModel.AmountRole)

            if (!dateStr || amount === undefined) continue

            hasData = true
            var date = new Date(dateStr)
            if (date < oldestDate) {
                oldestDate = date
            }

            var weekKey = getWeekKey(date)

            if (!weeks[weekKey]) {
                weeks[weekKey] = {
                    monday: weekKey,
                    total: 0
                }
            }

            weeks[weekKey].total += amount
        }

        // Calculate the start date for 12 weeks
        var endDate = getMonday(new Date())
        var startDate = new Date(endDate)
        startDate.setDate(startDate.getDate() - (11 * 7)) // 11 weeks back

        // Create all 12 weeks
        var weeksArray = []
        for (var j = 0; j < 12; j++) {
            var weekDate = new Date(startDate)
            weekDate.setDate(weekDate.getDate() + (j * 7))
            var key = getWeekKey(weekDate)

            weeksArray.push({
                                monday: key,
                                total: weeks[key] ? weeks[key].total : 0
                            })
        }

        root.weeklyTotals = weeksArray

        // Calculate max absolute value for scaling
        var maxAbs = 0
        for (var k = 0; k < weeksArray.length; k++) {
            var abs = Math.abs(weeksArray[k].total)
            if (abs > maxAbs) maxAbs = abs
        }
        root.maxAbsValue = maxAbs

        // Populate display model
        weeksDisplayModel.clear()
        for (var m = 0; m < weeksArray.length; m++) {
            weeksDisplayModel.append({
                                         weekLabel: root.formatWeekLabel(weeksArray[m].monday),
                                         weekTotal: weeksArray[m].total
                                     })
        }
    }

    function calculateFinancials() {
        root.weeklyIncome = 0
        root.weeklyOutcome = 0

        clientRepeater.model = null
        employeeRepeater.model = null

        clientRepeater.model = AppState.clientModel
        employeeRepeater.model = AppState.employeeModel

        scanTransactions()

        Qt.callLater(function() {
            root.weeklyRevenue = root.weeklyIncome - root.weeklyOutcome
        })
    }

    Component.onCompleted: calculateFinancials()

    onVisibleChanged: {
        if (visible) {
            calculateFinancials()
        }
    }

    ScrollView {
        width: parent.width
        height: parent.height
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: parent.width
            spacing: 0
            anchors.margins: 20

            Label {
                text: AppState.companySummaryModel.companyName + " - Financial Summary"
                font.pixelSize: 24
                font.bold: true
                color: Constants.primaryTextColor
                Layout.topMargin: 20
                Layout.leftMargin: 20
            }

            // Combined Grid Layout
            GridLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                columns: 3
                columnSpacing: 20
                rowSpacing: 20

                RowLayout {
                    Layout.columnSpan: 3
                    spacing: 20
                    Pane {
                        Layout.fillWidth: true
                        Material.elevation: 6
                        Material.background: Constants.listItemOdd

                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            Label {
                                text: "Current Balance"
                                font.pixelSize: 18
                                font.bold: true
                                color: Constants.secondaryTextColor
                            }

                            Label {
                                text: AppState.toUiPrice(AppState.companySummaryModel.money)
                                font.pixelSize: 32
                                font.bold: true
                                color: AppState.companySummaryModel.money >= 0 ? Constants.creditColor : Constants.debitColor
                            }
                        }
                    }
                    Pane {
                        Layout.fillWidth: true
                        Material.elevation: 6
                        Material.background: Constants.listItemOdd
                        visible: AppState.awaitingTransactionModel && AppState.awaitingTransactionModel.count > 0

                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            Label {
                                text: "Projected Balance"
                                font.pixelSize: 18
                                font.bold: true
                                color: Constants.secondaryTextColor
                            }

                            Label {
                                text: {
                                    var awaitingSum = 0
                                    if (AppState.awaitingTransactionModel) {
                                        for (var i = 0; i < AppState.awaitingTransactionModel.count; i++) {
                                            awaitingSum += AppState.awaitingTransactionModel.getAwaitingTransactionAmount(i)
                                        }
                                    }
                                    var projectedBalance = AppState.companySummaryModel.money + awaitingSum
                                    return AppState.toUiPrice(projectedBalance)
                                }
                                font.pixelSize: 32
                                font.bold: true
                                color: {
                                    if (AppState.awaitingTransactionModel && AppState.awaitingTransactionModel.count > 0) {
                                        return Material.color(Material.Orange)
                                    }
                                    return Constants.creditColor
                                }
                            }
                        }
                    }
                }

                // Row 1 - Weekly Estimates
                Pane {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    Material.elevation: 6
                    Material.background: Constants.listItemOdd

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: "Estimated Weekly Income"
                            font.pixelSize: 14
                            font.bold: true
                            color: Constants.secondaryTextColor
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            text: {
                                var priceText = AppState.toUiPrice(root.weeklyIncome)
                                if (priceText.startsWith("+") || priceText.startsWith("-")) {
                                    priceText = priceText.substring(1)
                                }
                                return priceText
                            }
                            font.pixelSize: 24
                            font.bold: true
                            color: Constants.creditColor
                        }

                        Label {
                            text: "From " + (AppState.clientModel ? AppState.clientModel.count : 0) + " clients"
                            font.pixelSize: 12
                            color: Constants.hintTextColor
                        }
                    }
                }

                Pane {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    Material.elevation: 6
                    Material.background: Constants.listItemOdd

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: "Estimated Weekly Outcome"
                            font.pixelSize: 14
                            font.bold: true
                            color: Constants.secondaryTextColor
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            text: {
                                var priceText = AppState.toUiPrice(root.weeklyOutcome)
                                if (priceText.startsWith("+") || priceText.startsWith("-")) {
                                    priceText = priceText.substring(1)
                                }
                                return priceText
                            }
                            font.pixelSize: 24
                            font.bold: true
                            color: Constants.debitColor
                        }

                        Label {
                            text: "Employee salaries"
                            font.pixelSize: 12
                            color: Constants.hintTextColor
                        }
                    }
                }

                Pane {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    Material.elevation: 6
                    Material.background: Constants.listItemOdd

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 10

                        Label {
                            text: "Estimated Weekly Revenue"
                            font.pixelSize: 14
                            font.bold: true
                            color: Constants.secondaryTextColor
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            text: AppState.toUiPrice(root.weeklyRevenue)
                            font.pixelSize: 24
                            font.bold: true
                            color: root.weeklyRevenue >= 0 ? Constants.creditColor : Constants.debitColor
                        }

                        Label {
                            text: root.weeklyRevenue >= 0 ? "Profitable" : "Loss"
                            font.pixelSize: 12
                            color: Constants.hintTextColor
                        }
                    }
                }

                // Row 2-3 - Performance Chart and Stats
                Pane {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 400
                    Layout.columnSpan: 2
                    Layout.rowSpan: 2
                    Material.elevation: 6
                    Material.background: Constants.listItemOdd

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        Label {
                            text: "Weekly Performance (Last 12 Weeks)"
                            font.pixelSize: 18
                            font.bold: true
                            color: Constants.secondaryTextColor
                        }

                        Item {
                            id: chartArea
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                y: 20 + (chartArea.height - 60) / 2
                                height: 2
                                color: Constants.hintTextColor
                                opacity: 0.3
                                z: 1
                            }

                            Row {
                                id: chartRow
                                anchors.fill: parent
                                anchors.margins: 20
                                spacing: 5

                                Repeater {
                                    model: weeksDisplayModel

                                    delegate: Item {
                                        id: barItem
                                        required property string weekLabel
                                        required property real weekTotal
                                        required property int index

                                        width: {
                                            var count = weeksDisplayModel.count
                                            if (count === 0) return 0
                                            return (chartRow.width - (count - 1) * 5) / count
                                        }
                                        height: chartRow.height

                                        Column {
                                            anchors.centerIn: parent
                                            spacing: 5
                                            width: parent.width

                                            Item {
                                                width: parent.width
                                                height: parent.parent.height - 40

                                                Rectangle {
                                                    id: bar
                                                    width: parent.width
                                                    anchors.horizontalCenter: parent.horizontalCenter

                                                    property real normalizedValue: root.maxAbsValue > 0 ? barItem.weekTotal / root.maxAbsValue : 0
                                                    property real maxBarHeight: parent.height / 2 - 20

                                                    height: Math.max(5, Math.abs(normalizedValue * maxBarHeight))
                                                    color: barItem.weekTotal >= 0 ? Constants.creditColor : Constants.debitColor
                                                    radius: 4

                                                    y: barItem.weekTotal >= 0 ?
                                                           (parent.height / 2 - height - 8) :
                                                           (parent.height / 2 + 8)

                                                    Label {
                                                        anchors.horizontalCenter: parent.horizontalCenter
                                                        y: barItem.weekTotal >= 0 ? -20 : bar.height + 5
                                                        text: AppState.toUiPrice(barItem.weekTotal)
                                                        font.pixelSize: 12
                                                        font.bold: true
                                                        color: barItem.weekTotal >= 0 ? Constants.creditColor : Constants.debitColor
                                                        visible: barItem.weekTotal !== 0
                                                    }
                                                }
                                            }

                                            Label {
                                                width: parent.width
                                                text: barItem.weekLabel
                                                font.pixelSize: 12
                                                font.bold: true
                                                horizontalAlignment: Text.AlignHCenter
                                                color: Constants.hintTextColor
                                                wrapMode: Text.WordWrap
                                                maximumLineCount: 2
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Pane {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    Material.elevation: 6
                    Material.background: Constants.listItemOdd

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        Label {
                            text: "Quick Stats"
                            font.pixelSize: 18
                            font.bold: true
                            color: Constants.secondaryTextColor
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 15

                            Label {
                                text: "Employees:"
                                font.bold: true
                                color: Constants.primaryTextColor
                            }
                            Label {
                                text: AppState.employeeModel ? AppState.employeeModel.count : 0
                                font.pixelSize: 18
                                font.bold: true
                                color: Constants.secondaryTextColor
                            }

                            Label {
                                text: "Clients:"
                                font.bold: true
                                color: Constants.primaryTextColor
                            }
                            Label {
                                text: AppState.clientModel ? AppState.clientModel.count : 0
                                font.pixelSize: 18
                                font.bold: true
                                color: Constants.secondaryTextColor
                            }

                            Label {
                                text: "Transactions:"
                                font.bold: true
                                color: Constants.primaryTextColor
                            }
                            Label {
                                text: AppState.transactionModel ? AppState.transactionModel.count : 0
                                font.pixelSize: 18
                                font.bold: true
                                color: Constants.secondaryTextColor
                            }

                            Label {
                                text: "Pending:"
                                font.bold: true
                                color: Constants.primaryTextColor
                            }
                            Label {
                                text: AppState.awaitingTransactionModel ? AppState.awaitingTransactionModel.count : 0
                                font.pixelSize: 18
                                font.bold: true
                                color: Material.color(Material.Orange)
                            }
                        }
                    }
                }

                Pane {
                    id: lastActivityCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    Material.elevation: 6
                    Material.background: Constants.listItemOdd

                    property var lastTransaction: null

                    Component.onCompleted: {
                        lastTransaction = root.getLastTransaction()
                    }

                    Connections {
                        target: AppState.transactionModel
                        function onCountChanged() { lastActivityCard.lastTransaction = root.getLastTransaction() }
                        function onRowsInserted() { lastActivityCard.lastTransaction = root.getLastTransaction() }
                        function onRowsRemoved() { lastActivityCard.lastTransaction = root.getLastTransaction() }
                        function onDataChanged() { lastActivityCard.lastTransaction = root.getLastTransaction() }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        Label {
                            text: "Last Activity"
                            font.pixelSize: 18
                            font.bold: true
                            color: Constants.secondaryTextColor
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            Label {
                                text: lastActivityCard.lastTransaction ? lastActivityCard.lastTransaction.description : "No transactions yet"
                                Layout.fillWidth: true
                                font.pixelSize: 14
                                font.bold: true
                                color: Constants.primaryTextColor
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            Label {
                                text: lastActivityCard.lastTransaction ? AppState.toUiPrice(lastActivityCard.lastTransaction.amount) : ""
                                font.pixelSize: 24
                                font.bold: true
                                color: lastActivityCard.lastTransaction ?
                                       (lastActivityCard.lastTransaction.amount >= 0 ? Constants.creditColor : Constants.debitColor) :
                                       Constants.secondaryTextColor
                            }

                            Label {
                                text: lastActivityCard.lastTransaction ? lastActivityCard.lastTransaction.date : ""
                                font.pixelSize: 12
                                color: Constants.hintTextColor
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
