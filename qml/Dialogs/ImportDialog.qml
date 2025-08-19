import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: "Import Data"
    width: 500
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    signal importRequested(string filePath)

    Column {
        width: parent.width
        spacing: 15

        Label {
            text: "Import data from a .gco backup file."
            width: parent.width
            wrapMode: Text.WordWrap
            font.bold: true
        }

        Label {
            text: "⚠️ WARNING: This will completely replace all your current data!"
            width: parent.width
            wrapMode: Text.WordWrap
            color: Material.color(Material.Red)
            font.bold: true
        }

        RowLayout {
            width: parent.width
            visible: Qt.platform.os !== "wasm"

            Label {
                text: "File path:"
                Layout.alignment: Qt.AlignVCenter
            }

            TextField {
                id: importPathField
                Layout.fillWidth: true
                text: DataManager.getDefaultImportPath()
                Layout.preferredHeight: 35
                placeholderText: "Choose backup file to import..."
            }

            ToolButton {
                text: "Browse..."
                icon.source: "qrc:/icons/folder.svg"
                icon.width: 16
                icon.height: 16
                Layout.preferredHeight: 40
                onClicked: importFileDialog.open()
            }
        }

        Label {
            text: "This will restore:\n• All employees, transactions, clients\n• Supplements and offers\n• User settings and balance"
            width: parent.width
            wrapMode: Text.WordWrap
            color: "gray"
            font.pixelSize: 12
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: Qt.platform.os === "wasm" ? "Choose File" : "Import"
            enabled: Qt.platform.os === "wasm" || importPathField.text.length > 0
            DialogButtonBox.buttonRole: Qt.platform.os === "wasm" ? DialogButtonBox.AcceptRole : DialogButtonBox.DestructiveRole
            onClicked: {
                if (Qt.platform.os === "wasm") {
                    root.importRequested("")
                } else {
                    root.importRequested(importPathField.text)
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

    FileDialog {
        id: importFileDialog
        title: "Open backup file"
        fileMode: FileDialog.OpenFile
        nameFilters: ["GTACOMPTA Backup Files (*.gco)", "All Files (*)"]
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            importPathField.text = selectedFile.toString().replace("file:///", "").replace("file://", "")
        }
    }
}
