pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Controls.impl
import QtQuick.Controls.Material.impl
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Page {
    id: root
    Material.primary: Constants.primaryColor
    Material.background: Constants.backgroundColor
    Material.accent: Constants.accentColor

    signal showSettings()
    signal showNotes()
    signal showFakeUpgrade()
    signal showVersion()
    signal showNewEmployee()
    signal showNewTransaction()
    signal showNewClient()
    signal showSupplementOfferManagement()
    signal showExport()
    signal showImport()
    signal clearAllData()

    background: Rectangle {
        color: Constants.surfaceColor
        layer.enabled: root.enabled && root.Material.elevation > 0
        layer.effect: ElevationEffect {
            elevation: root.Material.elevation
        }
    }

    header: ToolBar {
        height: 40
        Material.primary: Material.dialogColor

        Item {
            anchors.fill: parent

            MenuBar {
                anchors.left: parent.left
                height: 40

                Menu {
                    title: "File"

                    MenuItem {
                        text: "Settings"
                        onTriggered: root.showSettings()
                    }

                    MenuSeparator { }

                    MenuItem {
                        text: "Clear All Data"
                        onTriggered: root.clearAllData()
                    }

                    MenuItem {
                        text: "Exit"
                        enabled: Qt.platform.os !== "wasm"
                        height: Qt.platform.os !== "wasm" ? implicitHeight : 0
                        opacity: Qt.platform.os !== "wasm" ? 1.0 : 0.0
                        onTriggered: Qt.quit()
                    }
                }

                Menu {
                    title: "Databases"
                    MenuItem {
                        text: "New Employee..."
                        onTriggered: root.showNewEmployee()
                    }
                    MenuItem {
                        text: "New Transaction..."
                        onTriggered: root.showNewTransaction()
                    }
                    MenuItem {
                        text: "New Client..."
                        onTriggered: root.showNewClient()
                    }

                    MenuSeparator { }

                    MenuItem {
                        text: "Supplements and Offers..."
                        onTriggered: root.showSupplementOfferManagement()
                    }

                    MenuSeparator { }

                    MenuItem {
                        text: "Export Data..."
                        onTriggered: root.showExport()
                    }

                    MenuItem {
                        text: "Import Data..."
                        onTriggered: root.showImport()
                    }
                }

                Menu {
                    title: "Additions"
                    MenuItem {
                        text: "Notes"
                        onTriggered: root.showNotes()
                    }

                    MenuItem {
                        text: "Connect to FiveM"
                        onTriggered: root.showFakeUpgrade()
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
                    text: AppState.toUiPrice(UserSettings.money)
                    color: UserSettings.money >= 0 ? Constants.creditColor : Constants.debitColor
                    font.bold: true
                    font.pixelSize: 16
                }

                Label {
                    text: {
                        var awaitingSum = 0
                        if (AppState.awaitingTransactionModel) {
                            for (var i = 0; i < AppState.awaitingTransactionModel.count; i++) {
                                awaitingSum += AppState.awaitingTransactionModel.getAwaitingTransactionAmount(i)
                            }
                        }
                        var virtualTotal = UserSettings.money + awaitingSum
                        return "(" + AppState.toUiPrice(virtualTotal) + ")"
                    }
                    color: Material.color(Material.Orange)
                    font.bold: true
                    font.pixelSize: 16
                    visible: AppState.awaitingTransactionModel ? AppState.awaitingTransactionModel.count > 0 : false
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
                onTextChanged: AppState.filterText = text
            }

            Item {
                id: logo
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                height: 40
                width: 40
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.showVersion()
                }

                Image {
                    id: logoImage
                    anchors.centerIn: parent
                    height: 32
                    width: 32
                    sourceSize.width: 32
                    sourceSize.height: 32
                    mipmap: true
                    source: "qrc:/icons/icon.png"
                    transform: Rotation {
                        id: rotation3d
                        origin.x: logoImage.width / 2
                        origin.y: logoImage.height / 2
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
            text: "Employees (" + (AppState.filterText ? (AppState.employeeFilterModel ? AppState.employeeFilterModel.rowCount() + "/" + AppState.employeeModel.count : "0/0") : (AppState.employeeModel ? AppState.employeeModel.count : "0")) + ")"
        }
        TabButton {
            text: "Transactions (" + (AppState.filterText ? (AppState.transactionFilterModel ? AppState.transactionFilterModel.rowCount() + "/" + AppState.transactionModel.count : "0/0") : (AppState.transactionModel ? AppState.transactionModel.count : "0")) + ")"
        }
        TabButton {
            text: "Awaiting (" + (AppState.filterText ? (AppState.awaitingTransactionFilterModel ? AppState.awaitingTransactionFilterModel.rowCount() + "/" + AppState.awaitingTransactionModel.count : "0/0") : (AppState.awaitingTransactionModel ? AppState.awaitingTransactionModel.count : "0")) + ")"
        }
        TabButton {
            text: "Clients (" + (AppState.filterText ? (AppState.clientFilterModel ? AppState.clientFilterModel.rowCount() + "/" + AppState.clientModel.count : "0/0") : (AppState.clientModel ? AppState.clientModel.count : "0")) + ")"
        }
    }

    StackView {
        id: stackView
        anchors.top: tabBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right

        property int previousIndex: 0
        property bool isMovingForward: false

        replaceEnter: Transition {
            XAnimator {
                from: stackView.isMovingForward ? stackView.width : -stackView.width
                to: 0
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        replaceExit: Transition {
            XAnimator {
                from: 0
                to: stackView.isMovingForward ? -stackView.width : stackView.width
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        Component {
            id: employeeComponent
            EmployeeTab {}
        }

        Component {
            id: transactionComponent
            TransactionTab {}
        }

        Component {
            id: awaitingComponent
            AwaitingTransactionTab {}
        }

        Component {
            id: clientComponent
            ClientTab {}
        }

        initialItem: employeeComponent
    }

    Connections {
        target: tabBar
        function onCurrentIndexChanged() {
            var components = [employeeComponent, transactionComponent, awaitingComponent, clientComponent]
            if (tabBar.currentIndex < components.length) {
                stackView.isMovingForward = tabBar.currentIndex > stackView.previousIndex

                if (stackView.depth === 0) {
                    stackView.push(components[tabBar.currentIndex])
                } else {
                    stackView.replace(components[tabBar.currentIndex])
                }

                stackView.previousIndex = tabBar.currentIndex
            }
        }
    }
}
