pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Odizinne.GTACOMPTA

Dialog {
    id: root
    title: readOnly ? "View Supplements" : "Select Supplements"
    width: 450
    anchors.centerIn: parent
    modal: true
    Material.roundedScale: Material.ExtraSmallScale

    property var currentSupplements: ({})
    property bool readOnly: false

    signal supplementsSelected(var quantities)

    function getSelectedSupplements() {
        var selected = []
        var quantities = {}

        for (var i = 0; i < supplementRepeater.count; i++) {
            var spinBox = supplementRepeater.itemAt(i).children[1]
            if (spinBox.value > 0) {
                selected.push(i)
                quantities[i.toString()] = spinBox.value
            }
        }

        return {
            selectedList: selected,
            quantities: quantities
        }
    }

    function setSelectedSupplements(supplements) {
        for (var i = 0; i < supplementRepeater.count; i++) {
            var spinBox = supplementRepeater.itemAt(i).children[1]
            var quantity = supplements[i.toString()] || 0
            spinBox.value = quantity
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
                model: AppState.supplementModel

                delegate: RowLayout {
                    id: del
                    width: parent.width
                    spacing: 10
                    required property var model

                    Label {
                        text: del.model.name + " - " + AppState.toUiPrice(del.model.price)
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    SpinBox {
                        Layout.preferredWidth: 120
                        from: 0
                        to: 999
                        value: 0
                        enabled: !root.readOnly
                        Layout.preferredHeight: Constants.comboHeight

                        textFromValue: function(value, locale) {
                            return value === 0 ? "None" : value.toString()
                        }
                    }
                }
            }
        }
    }

    footer: DialogButtonBox {
        Repeater {
            model: root.readOnly ? [
                                       {text: "OK", role: DialogButtonBox.AcceptRole, action: function() { root.close() }}
                                   ] : [
                                       {text: "Apply", role: DialogButtonBox.AcceptRole, action: function() {
                                           var result = root.getSelectedSupplements()
                                           root.supplementsSelected(result.quantities)
                                           root.close()
                                       }},
                                       {text: "Cancel", role: DialogButtonBox.RejectRole, action: function() { root.close() }}
                                   ]

            delegate: Button {
                flat: true
                text: model.text
                DialogButtonBox.buttonRole: model.role
                onClicked: model.action()
                required property var model
            }
        }
    }
}
