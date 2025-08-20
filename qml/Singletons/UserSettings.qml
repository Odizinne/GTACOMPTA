pragma Singleton

import QtCore

Settings {
    property int money: 0
    property bool firstRun: true
    property string companyName: ""
    property string notes: ""
    property bool darkMode: true

    property bool useRemoteDatabase: false
    property string remoteHost: "localhost"
    property int remotePort: 3000
    property string remotePassword: "1234"
}
