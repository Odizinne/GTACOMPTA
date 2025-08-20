pragma Singleton

import QtQuick
import QtQuick.Controls.Material

Item {
    property int comboHeight: 35
    property color creditColor: Material.color(Material.Green)
    property color debitColor: Material.color(Material.Red)
    property color consumerColor: Material.color(Material.Teal)
    property color businessColor: Material.color(Material.Amber)

    // Theme colors
    property color primaryColor: UserSettings.darkMode ? "#2A2F2A" : "#C8D5C8"
    property color backgroundColor: UserSettings.darkMode ? "#232323" : "#E5E5E5"
    property color surfaceColor: UserSettings.darkMode ? "#1A1A1A" : "#FFFFFF"
    property color accentColor: "#4CAF50"

    // List item colors
    property color listItemEven: UserSettings.darkMode ? "#404040" : "#FCFCFC"
    property color listItemOdd: UserSettings.darkMode ? "#303030" : "#E5E5E5"

    // Text colors
    property color primaryTextColor: UserSettings.darkMode ? "#FFFFFF" : "#212121"
    property color secondaryTextColor: UserSettings.darkMode ? "#B0B0B0" : "#757575"
    property color hintTextColor: UserSettings.darkMode ? "#808080" : "#9E9E9E"

    // Gradient colors for splash
    property color gradientStart: UserSettings.darkMode ? "#2A2F2A" : "#E8F5E8"
    property color gradientEnd: UserSettings.darkMode ? "#1A1A1A" : "#C8E6C9"

    // Positive/negative amount colors
    property color positiveAmountColor: UserSettings.darkMode ? "lightgreen" : "#2E7D32"
    property color negativeAmountColor: UserSettings.darkMode ? "lightcoral" : "#C62828"

    // Salary/price color
    property color salaryColor: UserSettings.darkMode ? "lightgreen" : "#388E3C"
}
