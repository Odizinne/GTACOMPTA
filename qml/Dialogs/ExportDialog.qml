import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: "Export Data"
    width: 500
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    signal exportRequested(string filePath)

    Column {
        width: parent.width
        spacing: 15

        Label {
            text: "Export all your data to a .gco backup file."
            width: parent.width
            wrapMode: Text.WordWrap
        }

        RowLayout {
            width: parent.width
            visible: Qt.platform.os !== "wasm"

            Label {
                text: "File path:"
                Layout.alignment: Qt.AlignVCenter
            }

            TextField {
                id: exportPathField
                Layout.fillWidth: true
                text: DataManager.getDefaultExportPath()
                Layout.preferredHeight: 35
                placeholderText: "Choose export location..."
            }

            ToolButton {
                text: "Browse..."
                icon.source: "qrc:/icons/folder.svg"
                icon.width: 16
                icon.height: 16
                Layout.preferredHeight: 40
                onClicked: exportFileDialog.open()
            }
        }

        Label {
            text: "This will create a backup containing:\n• All employees, transactions, clients\n• Supplements and offers\n• User settings and balance"
            width: parent.width
            wrapMode: Text.WordWrap
            color: "gray"
            font.pixelSize: 12
        }
    }

    footer: DialogButtonBox {
        Button {
            flat: true
            text: "Export"
            enabled: Qt.platform.os === "wasm" || exportPathField.text.length > 0
            DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            onClicked: {
                if (Qt.platform.os === "wasm") {
                    root.exportRequested("")
                } else {
                    root.exportRequested(exportPathField.text)
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
        id: exportFileDialog
        title: "Save backup file"
        fileMode: FileDialog.SaveFile
        nameFilters: ["GTACOMPTA Backup Files (*.gco)", "All Files (*)"]
        defaultSuffix: "gco"
        currentFolder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
        onAccepted: {
            exportPathField.text = selectedFile.toString().replace("file:///", "").replace("file://", "")
        }
    }
}
